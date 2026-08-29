#!/usr/bin/env python3
"""Neo4j 5.26 离线二进制 dump + 加载 + 一致性校验
参考 Neo4j_Docker_备份_恢复与一致性校验指南 3.x / 5.x / 6.x / 7.x
"""
import argparse
import os
import shlex
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DEFAULT_CONTAINER = "infra-neo4j"
DEFAULT_IMAGE = "neo4j:5.26.0"
DEFAULT_DB = "neo4j"
DEFAULT_USER = "neo4j"
DEFAULT_PASSWORD = "neo4j123"
DEFAULT_VOLUME = "infra_neo4j-data"
DEFAULT_BACKUP_ROOT = "/Users/fanyong/Desktop/code/python/docker_server/my_assistant/数据库数据备份"


def docker(*args, check=True, capture=True):
    cmd = ["docker", *args]
    if capture:
        r = subprocess.run(cmd, capture_output=True, text=True)
        if check and r.returncode != 0:
            sys.stderr.write(r.stderr)
            sys.exit(f"docker {' '.join(args)} failed: {r.returncode}")
        return r
    return subprocess.run(cmd)


def container_running(name):
    r = docker("ps", "--filter", f"name=^/{name}$", "--format", "{{.Names}}")
    return name in r.stdout.strip().splitlines()


def stop_container(name):
    if container_running(name):
        print(f"[stop] {name}")
        docker("stop", name)
    r = docker("ps", "-a", "--filter", f"name=^/{name}$", "--format", "{{.Status}}")
    assert "Exited" in r.stdout or r.stdout.strip() == "", f"container not stopped: {r.stdout}"


def start_container(name):
    docker("start", name)
    print(f"[start] {name}")


def dump_offline(args, out_dir):
    stop_container(args.container)
    print(f"[dump] neo4j -> {out_dir}")
    r = docker(
        "run", "--rm",
        "-v", f"{args.volume}:/data",
        "-v", f"{out_dir}:/backups",
        args.image,
        "neo4j-admin", "database", "dump", args.db,
        "--to-path=/backups",
        check=False,
    )
    start_container(args.container)
    if r.returncode != 0:
        sys.exit(f"neo4j-admin dump failed: {r.stderr}")
    dump = out_dir / "neo4j.dump"
    if not dump.exists() or dump.stat().st_size == 0:
        sys.exit("dump file missing or empty")
    print(f"[done] {dump}  {dump.stat().st_size/1024/1024:.1f}MB")


def dump_online_cypher(args, out_file):
    print(f"[online cypher-shell dump] -> {out_file}")
    out_file.parent.mkdir(parents=True, exist_ok=True)
    head = docker("exec", args.container, "cypher-shell",
                  "-u", args.user, "-p", args.password, args.db,
                  "CALL db.labels();")
    if head.returncode != 0:
        sys.exit(head.stderr)
    head.stdout.splitlines()[:200]
    r = docker("exec", args.container, "cypher-shell",
               "-u", args.user, "-p", args.password, args.db,
               "MATCH (n)-[r]->(m) RETURN n, r, m;", check=False)
    out_file.write_text(r.stdout, encoding="utf-8")
    if r.returncode != 0:
        sys.exit(f"online dump failed: {r.stderr}")
    print(f"[done] {out_file}")


def load_offline(args, dump_file):
    if not dump_file.exists():
        sys.exit(f"dump not found: {dump_file}")
    stop_container(args.container)
    print(f"[load] {dump_file} -> {args.volume}")
    r = docker(
        "run", "--rm",
        "-v", f"{args.volume}:/data",
        "-v", f"{dump_file.parent}:/backups:ro",
        args.image,
        "neo4j-admin", "database", "load", args.db,
        f"--from-path=/backups",
        "--overwrite-destination=true",
        check=False,
    )
    start_container(args.container)
    if r.returncode != 0:
        sys.exit(f"neo4j-admin load failed: {r.stderr}")
    print("[done] load + restart")


def write_validation_cypher(path: Path):
    sections = [
        ("01_DBMS_COMPONENTS", [
            "CALL dbms.components() YIELD name, versions, edition "
            "RETURN name, versions, edition ORDER BY name;",
        ]),
        ("02_DATABASE_INFO", [
            "SHOW DATABASE neo4j YIELD name, type, access, requestedStatus, "
            "currentStatus, `default`, home RETURN name, type, access, "
            "requestedStatus, currentStatus, `default`, home;",
            "CALL db.info();",
        ]),
        ("03_TOTALS", [
            "MATCH (n) RETURN count(n) AS nodeCount;",
            "MATCH ()-[r]->() RETURN count(r) AS relationshipCount;",
        ]),
        ("04_LABELS", [
            "CALL db.labels() YIELD label RETURN label ORDER BY label;",
            "MATCH (n) UNWIND labels(n) AS label "
            "RETURN label, count(*) AS nodeCount ORDER BY label;",
            "MATCH (n) WHERE labels(n) = [] RETURN count(n) AS unlabeledNodeCount;",
        ]),
        ("05_RELATIONSHIP_TYPES", [
            "CALL db.relationshipTypes() YIELD relationshipType "
            "RETURN relationshipType ORDER BY relationshipType;",
            "MATCH ()-[r]->() RETURN type(r) AS relationshipType, "
            "count(*) AS relationshipCount ORDER BY relationshipType;",
        ]),
        ("06_PROPERTY_KEYS", [
            "CALL db.propertyKeys() YIELD propertyKey "
            "RETURN propertyKey ORDER BY propertyKey;",
        ]),
        ("07_NODE_PROPERTY_COVERAGE_GLOBAL", [
            "MATCH (n) WITH collect(n) AS nodes, count(n) AS totalNodes "
            "UNWIND nodes AS n UNWIND keys(n) AS propertyKey "
            "RETURN propertyKey, totalNodes, count(*) AS nodesWithProperty, "
            "round(100.0 * count(*)/totalNodes, 2) AS coveragePct "
            "ORDER BY propertyKey;",
        ]),
        ("08_NODE_PROPERTY_COVERAGE_BY_LABEL", [
            "MATCH (n) UNWIND labels(n) AS label WITH label, collect(n) AS nodes, "
            "count(n) AS totalNodes UNWIND nodes AS n UNWIND keys(n) AS propertyKey "
            "RETURN label, propertyKey, totalNodes, count(*) AS nodesWithProperty, "
            "round(100.0 * count(*)/totalNodes, 2) AS coveragePct "
            "ORDER BY label, propertyKey;",
        ]),
        ("09_REL_PROPERTY_COVERAGE_BY_TYPE", [
            "MATCH ()-[r]->() WITH type(r) AS relationshipType, collect(r) AS rs, "
            "count(r) AS totalR UNWIND rs AS r UNWIND keys(r) AS propertyKey "
            "RETURN relationshipType, propertyKey, totalR, count(*) AS relsWithProperty, "
            "round(100.0 * count(*)/totalR, 2) AS coveragePct "
            "ORDER BY relationshipType, propertyKey;",
        ]),
        ("10_NODE_VALUE_TYPES", [
            "MATCH (n) UNWIND labels(n) AS label UNWIND keys(n) AS propertyKey "
            "RETURN label, propertyKey, valueType(n[propertyKey]) AS valueType, "
            "count(*) AS valueCount ORDER BY label, propertyKey, valueType;",
        ]),
        ("11_REL_VALUE_TYPES", [
            "MATCH ()-[r]->() UNWIND keys(r) AS propertyKey "
            "RETURN type(r) AS relationshipType, propertyKey, "
            "valueType(r[propertyKey]) AS valueType, count(*) AS valueCount "
            "ORDER BY relationshipType, propertyKey, valueType;",
        ]),
        ("12_CONSTRAINTS", [
            "SHOW CONSTRAINTS YIELD name, type, entityType, labelsOrTypes, "
            "properties, ownedIndex RETURN name, type, entityType, labelsOrTypes, "
            "properties, ownedIndex ORDER BY name;",
        ]),
        ("13_INDEXES", [
            "SHOW INDEXES YIELD name, state, populationPercent, type, entityType, "
            "labelsOrTypes, properties, indexProvider, owningConstraint "
            "RETURN name, state, populationPercent, type, entityType, labelsOrTypes, "
            "properties, indexProvider, owningConstraint ORDER BY name;",
        ]),
    ]
    lines = []
    for name, stmts in sections:
        lines.append(f"// ===== {name} =====")
        for s in stmts:
            lines.append(s)
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def validate(args, out_dir: Path):
    val_dir = out_dir / "validation"
    val_dir.mkdir(parents=True, exist_ok=True)
    cypher = val_dir / "validation.cypher"
    write_validation_cypher(cypher)

    def run(container, label):
        r = docker("exec", "-i", container, "cypher-shell",
                   "-u", args.user, "-p", args.password, args.db,
                   "--format", "plain", check=False)
        r_stdout = r.stdout  # already captured
        if r.returncode != 0:
            sys.exit(f"{label} cypher-shell failed: {r.stderr}")
        target = val_dir / f"{label}.txt"
        target.write_text(r_stdout, encoding="utf-8")
        print(f"[validate] {label} -> {target}")

    run(args.container, "original")

    test_container = "neo4j-restore-test"
    test_volume = "neo4j-restore-test-data"
    if args.with_restore_test:
        if not (out_dir / "neo4j.dump").exists():
            sys.exit("dump/neo4j.dump missing; run dump first")
        r = subprocess.run(["docker", "ps", "-a", "--filter", f"name=^/{test_container}$",
                            "--format", "{{.Names}}"], capture_output=True, text=True)
        if test_container in r.stdout:
            docker("rm", "-f", test_container)
        r = subprocess.run(["docker", "volume", "ls", "--filter", f"name=^{test_volume}$",
                            "--format", "{{.Name}}"], capture_output=True, text=True)
        if test_volume in r.stdout:
            docker("volume", "rm", test_volume)
        docker("volume", "create", test_volume)
        docker("run", "--rm",
               "-v", f"{test_volume}:/data",
               "-v", f"{out_dir}:/backups:ro",
               args.image,
               "neo4j-admin", "database", "load", args.db,
               "--from-path=/backups")
        docker("run", "-d", "--name", test_container,
               "-p", "17474:7474", "-p", "17687:7687",
               "-v", f"{test_volume}:/data",
               "-e", f"NEO4J_AUTH=neo4j/{args.restore_test_password}",
               args.image)
        print(f"[validate] waiting {test_container} ...")
        subprocess.run(["docker", "exec", test_container, "cypher-shell",
                        "-u", "neo4j", "-p", args.restore_test_password, args.db,
                        "RETURN 1 AS ok"], check=False)

        def run_test():
            r = subprocess.run(["docker", "exec", "-i", test_container, "cypher-shell",
                                "-u", "neo4j", "-p", args.restore_test_password, args.db,
                                "--format", "plain"], input=cypher.read_text(encoding="utf-8"),
                               capture_output=True, text=True, check=False)
            if r.returncode != 0:
                sys.exit(f"restore-test cypher-shell failed: {r.stderr}")
            return r.stdout

        restored_txt = val_dir / "restored.txt"
        restored_txt.write_text(run_test(), encoding="utf-8")

        diff_file = val_dir / "differences.diff"
        diff_r = subprocess.run(["diff", "-u",
                                 str(val_dir / "original.txt"),
                                 str(restored_txt)], capture_output=True, text=True)
        diff_file.write_text(diff_r.stdout, encoding="utf-8")
        print(f"[validate] diff -> {diff_file}  ({len(diff_r.stdout)} lines)")

        sha_o = subprocess.run(["shasum", "-a", "256", str(val_dir / "original.txt")],
                               capture_output=True, text=True).stdout.strip()
        sha_r = subprocess.run(["shasum", "-a", "256", str(restored_txt)],
                               capture_output=True, text=True).stdout.strip()
        (val_dir / "sha256.txt").write_text(f"original\t{sha_o}\nrestored\t{sha_r}\n",
                                            encoding="utf-8")
        print(f"[validate] sha256 -> {val_dir/'sha256.txt'}")

        if not args.keep_test:
            docker("stop", test_container)
            docker("rm", test_container)
            docker("volume", "rm", test_volume)


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--container", default=DEFAULT_CONTAINER)
    p.add_argument("--image", default=DEFAULT_IMAGE)
    p.add_argument("--db", default=DEFAULT_DB)
    p.add_argument("--user", default=DEFAULT_USER)
    p.add_argument("--password",
                   default=os.getenv("NEO4J_PASSWORD", DEFAULT_PASSWORD))
    p.add_argument("--volume", default=DEFAULT_VOLUME)
    p.add_argument("--backup-root", default=DEFAULT_BACKUP_ROOT)
    p.add_argument("--output", default=None,
                   help="dump 输出目录（默认 <backup-root>/<ts>）")

    sub = p.add_subparsers(dest="cmd", required=True)
    sp = sub.add_parser("dump", help="离线二进制 dump（停容器）")
    sp.add_argument("--online", action="store_true",
                    help="改用 cypher-shell 在线导出（不推荐）")

    sub.add_parser("load", help="从 dump 覆盖恢复到原 volume")
    p.add_argument("--dump-file", default=None)

    sub.add_parser("validate", help="13 段一致性校验")
    p.add_argument("--with-restore-test", action="store_true",
                   help="加载 dump 到 neo4j-restore-test-volume 并 diff")
    p.add_argument("--restore-test-password", default="TempPass_2026_ChangeMe")
    p.add_argument("--keep-test", action="store_true")
    return p


def main():
    p = parse_args()
    args = p.parse_args()

    if args.cmd in ("dump", "validate"):
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        out_dir = Path(args.output) if args.output else Path(args.backup_root) / ts
    else:
        out_dir = Path(args.backup_root)

    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"container={args.container}  volume={args.volume}  db={args.db}")
    print(f"output_dir={out_dir}")

    if args.cmd == "dump":
        if args.online:
            dump_online_cypher(args, out_dir / f"neo4j_{ts}.cypher")
        else:
            dump_offline(args, out_dir)
    elif args.cmd == "load":
        dump_file = Path(args.dump_file) if args.dump_file else out_dir / "neo4j.dump"
        load_offline(args, dump_file)
    elif args.cmd == "validate":
        validate(args, out_dir)


if __name__ == "__main__":
    main()
