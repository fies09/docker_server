#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time
import traceback
from datetime import datetime
from pathlib import Path
from pymilvus import connections, utility, Collection

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = "19530"
DEFAULT_BACKUP_ROOT = "/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份"
BATCH_SIZE = 1000


def parse_args():
    p = argparse.ArgumentParser(description="Export Milvus collections to JSONL backup")
    p.add_argument("--host", default=DEFAULT_HOST)
    p.add_argument("--port", default=DEFAULT_PORT)
    p.add_argument("--backup-root", default=DEFAULT_BACKUP_ROOT)
    p.add_argument("--batch-size", type=int, default=BATCH_SIZE)
    p.add_argument("--only", default=None, help="Comma-separated collection names")
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args()


def _normalize(value):
    if isinstance(value, list):
        return [_normalize(v) for v in value]
    if isinstance(value, dict):
        return {k: _normalize(v) for k, v in value.items()}
    if hasattr(value, "iso_format"):
        return value.iso_format()
    return value


def export_collection(name, out_dir, batch_size):
    schema_path = out_dir / f"{name}_schema.json"
    data_path = out_dir / f"{name}_data.jsonl"
    coll = Collection(name)
    coll.load()
    coll.flush()
    total = coll.num_entities

    schema = {
        "name": name,
        "description": coll.schema.description,
        "auto_id": coll.schema.auto_id,
        "fields": [
            {
                "name": f.name,
                "type": str(f.dtype).split(".")[-1].rstrip("'>").split("'")[0],
                "is_primary": f.is_primary,
                "auto_id": f.auto_id,
                "max_length": f.params.get("max_length"),
                "dim": f.params.get("dim"),
            }
            for f in coll.schema.fields
        ],
    }
    schema_path.write_text(json.dumps(schema, ensure_ascii=False, indent=2), encoding="utf-8")

    exported = 0
    size_bytes = 0
    if total > 0:
        it = coll.query_iterator(batch_size=batch_size)
        with open(data_path, "w", encoding="utf-8") as f:
            while True:
                batch = it.next()
                if not batch:
                    break
                for row in batch:
                    line = json.dumps(_normalize(row), ensure_ascii=False) + "\n"
                    f.write(line)
                    size_bytes += len(line.encode("utf-8"))
                exported += len(batch)
                print(f"    {exported}/{total}", end="\r", flush=True)
        it.close()
    print(f"    {exported}/{total} rows  {size_bytes/1024/1024:.1f}MB  ✓")
    return {"name": name, "rows": exported, "size_bytes": size_bytes, "status": "ok"}


def main():
    args = parse_args()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_root = Path(args.backup_root) / f"milvus_backup_{ts}"
    out_root.mkdir(parents=True, exist_ok=True)

    print(f"Connect  : {args.host}:{args.port}")
    connections.connect(host=args.host, port=args.port, timeout=10)
    cols = utility.list_collections()
    if args.only:
        wanted = set(s.strip() for s in args.only.split(","))
        cols = [c for c in cols if c in wanted]

    print(f"Backup to: {out_root}")
    print(f"Targets  : {len(cols)} collections")

    if args.dry_run:
        for c in cols:
            n = Collection(c).num_entities
            print(f"  {c}: {n} rows")
        return

    results = []
    total_rows = 0
    started = time.time()
    for i, name in enumerate(cols, 1):
        print(f"[{i}/{len(cols)}] {name}")
        try:
            r = export_collection(name, out_root, args.batch_size)
            results.append(r)
            total_rows += r["rows"]
        except Exception as e:
            print(f"    ERROR: {e}")
            traceback.print_exc()
            results.append({"name": name, "status": "error", "rows": 0, "size_bytes": 0})

    elapsed = time.time() - started
    ok = sum(1 for r in results if r["status"] == "ok")
    failed = sum(1 for r in results if r["status"] == "error")
    report = {
        "timestamp": datetime.now().isoformat(),
        "milvus_server": f"{args.host}:{args.port}",
        "backup_dir": str(out_root),
        "statistics": {
            "total_collections": len(cols),
            "success_collections": ok,
            "failed_collections": failed,
            "total_rows": total_rows,
            "elapsed_seconds": round(elapsed, 1),
        },
        "collections": results,
    }
    (out_root / "backup_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n=== Summary ===")
    print(f"OK     : {ok}/{len(cols)}")
    print(f"Failed : {failed}")
    print(f"Rows   : {total_rows}")
    print(f"Time   : {elapsed:.1f}s")
    print(f"Dir    : {out_root}")


if __name__ == "__main__":
    main()
