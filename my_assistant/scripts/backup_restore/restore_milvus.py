#!/usr/bin/env python3
import argparse
import json
import sys
import time
import traceback
from pathlib import Path
from pymilvus import connections, utility, Collection, FieldSchema, CollectionSchema, DataType

DEFAULT_BACKUP_DIR = "/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份/20260310/milvus_backup_20260114131423"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = "19530"
BATCH_SIZE = 500

TYPE_MAP = {
    "VARCHAR": DataType.VARCHAR, "INT64": DataType.INT64, "INT32": DataType.INT32,
    "FLOAT": DataType.FLOAT, "DOUBLE": DataType.DOUBLE, "BOOL": DataType.BOOL,
    "ARRAY": DataType.ARRAY, "FLOAT_VECTOR": DataType.FLOAT_VECTOR, "JSON": DataType.JSON,
}


def parse_args():
    p = argparse.ArgumentParser(description="Restore Milvus collections from JSONL backup directory")
    p.add_argument("--backup-dir", default=DEFAULT_BACKUP_DIR, help="Backup root containing <collection>/{schema,data}.json")
    p.add_argument("--host", default=DEFAULT_HOST)
    p.add_argument("--port", default=DEFAULT_PORT)
    p.add_argument("--batch-size", type=int, default=BATCH_SIZE)
    p.add_argument("--dry-run", action="store_true", help="List collections and counts without connecting/inserting")
    p.add_argument("--only", default=None, help="Restore only the named collection (comma-separated allowed)")
    p.add_argument("--skip-existing", action="store_true", help="Skip collections that already exist instead of dropping")
    return p.parse_args()


def build_schema(schema_dict):
    vector_count = 0
    fields = []
    for f in schema_dict["fields"]:
        kwargs = {"name": f["name"], "is_primary": f.get("is_primary", False)}
        dt = TYPE_MAP.get(f["type"].upper(), DataType.VARCHAR)
        if dt == DataType.VARCHAR:
            kwargs["max_length"] = f.get("max_length") or 512
        elif dt == DataType.FLOAT_VECTOR:
            if vector_count >= 4:
                continue
            vector_count += 1
            kwargs["dim"] = f.get("dim")
        elif dt == DataType.ARRAY:
            cap = f.get("max_length") or 256
            kwargs["max_capacity"] = cap
            kwargs["max_length"] = cap
            kwargs["element_type"] = DataType.VARCHAR
        fields.append(FieldSchema(dtype=dt, **kwargs))
    return CollectionSchema(
        fields=fields,
        description=schema_dict.get("description", ""),
        enable_dynamic_field=False,
    )


def read_jsonl(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def restore_one(name, coll_dir, args):
    schema_path = coll_dir / f"{name}_schema.json"
    data_path = coll_dir / f"{name}_data.jsonl"
    if not schema_path.exists():
        print(f"  [{name}] SKIP (no schema)")
        return {"name": name, "status": "skip", "rows": 0}
    if not data_path.exists():
        print(f"  [{name}] SKIP (no data file, schema-only collection)")
        return {"name": name, "status": "skip", "rows": 0}

    schema_dict = json.loads(schema_path.read_text(encoding="utf-8"))
    rows = read_jsonl(data_path)
    if not rows:
        print(f"  [{name}] SKIP (0 rows)")
        return {"name": name, "status": "skip", "rows": 0}

    if utility.has_collection(name):
        if args.skip_existing:
            print(f"  [{name}] SKIP (already exists, --skip-existing)")
            return {"name": name, "status": "skip", "rows": 0}
        print(f"  [{name}] drop existing")
        utility.drop_collection(name)

    schema = build_schema(schema_dict)
    coll = Collection(name=name, schema=schema)

    field_names = [f.name for f in schema.fields]
    inserted = 0
    for i in range(0, len(rows), args.batch_size):
        batch = rows[i:i + args.batch_size]
        entity = [row for row in batch]
        coll.insert(entity)
        inserted += len(batch)
    coll.flush()
    print(f"  [{name}] inserted {inserted} rows")
    return {"name": name, "status": "ok", "rows": inserted}


def main():
    args = parse_args()
    backup_dir = Path(args.backup_dir)
    if not backup_dir.is_dir():
        sys.exit(f"backup dir not found: {backup_dir}")

    subdirs = sorted([d for d in backup_dir.iterdir() if d.is_dir()])
    targets = [d for d in subdirs if (d / f"{d.name}_schema.json").exists()]
    if args.only:
        wanted = set(s.strip() for s in args.only.split(","))
        targets = [d for d in targets if d.name in wanted]

    print(f"Backup dir : {backup_dir}")
    print(f"Candidates : {len(targets)} collections")
    if args.dry_run:
        for d in targets:
            schema_p = d / f"{d.name}_schema.json"
            data_p = d / f"{d.name}_data.jsonl"
            row_count = sum(1 for _ in open(data_p, encoding="utf-8")) if data_p.exists() else 0
            print(f"  {d.name:50s} schema=YES  data={'YES' if data_p.exists() else 'NO '}  rows={row_count}")
        print("\nDRY-RUN, nothing connected/inserted.")
        return

    print(f"Connecting  : {args.host}:{args.port}")
    connections.connect(host=args.host, port=args.port)
    print(f"Connected.")

    results = []
    total = len(targets)
    started = time.time()
    for idx, d in enumerate(targets, 1):
        print(f"[{idx}/{total}] {d.name}")
        try:
            r = restore_one(d.name, d, args)
        except Exception as e:
            print(f"  [{d.name}] ERROR: {e}")
            traceback.print_exc()
            r = {"name": d.name, "status": "error", "rows": 0}
        results.append(r)

    elapsed = time.time() - started
    ok = sum(1 for r in results if r["status"] == "ok")
    skipped = sum(1 for r in results if r["status"] == "skip")
    failed = sum(1 for r in results if r["status"] == "error")
    total_rows = sum(r["rows"] for r in results)
    print(f"\n=== Summary ===")
    print(f"Total   : {total}")
    print(f"OK      : {ok}")
    print(f"Skip    : {skipped}")
    print(f"Failed  : {failed}")
    print(f"Rows    : {total_rows}")
    print(f"Elapsed : {elapsed:.1f}s")
    print(f"\nCollections now in Milvus: {utility.list_collections()}")


if __name__ == "__main__":
    main()
