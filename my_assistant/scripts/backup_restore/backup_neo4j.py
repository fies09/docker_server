#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DEFAULT_CONTAINER = "ma-neo4j"
DEFAULT_USER = "neo4j"
DEFAULT_PASSWORD = "neo4j123"
DEFAULT_BACKUP_ROOT = "/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份"


def parse_args():
    p = argparse.ArgumentParser(description="Neo4j logical dump via cypher-shell")
    p.add_argument("--container", default=DEFAULT_CONTAINER)
    p.add_argument("--user", default=DEFAULT_USER)
    p.add_argument("--password", default=os.getenv("NEO4J_PASSWORD", DEFAULT_PASSWORD))
    p.add_argument("--backup-root", default=DEFAULT_BACKUP_ROOT)
    p.add_argument("--output", default=None)
    return p.parse_args()


def main():
    args = parse_args()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = Path(args.output) if args.output else Path(args.backup_root) / f"neo4j_{ts}.cypher"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Container : {args.container}")
    print(f"Output    : {out_path}")

    header = f"// Neo4j dump {ts}\n"
    out_path.write_text(header, encoding="utf-8")

    cmd_list = [
        ('MATCH (n) RETURN labels(n) AS label, keys(n) AS keys, properties(n) AS props LIMIT 0;',
         'echo "schema probe ok"'),
    ]

    nodes = subprocess.run(
        ["docker", "exec", args.container, "cypher-shell",
         "-u", args.user, "-p", args.password,
         "MATCH (n) RETURN id(n) AS id, labels(n) AS labels, properties(n) AS props;"],
        capture_output=True, text=True,
    )
    if nodes.returncode != 0:
        sys.exit(f"node dump failed: {nodes.stderr}")
    (out_path.with_suffix(".nodes.cypher")).write_text(nodes.stdout, encoding="utf-8")

    rels = subprocess.run(
        ["docker", "exec", args.container, "cypher-shell",
         "-u", args.user, "-p", args.password,
         "MATCH ()-[r]->() RETURN id(startNode(r)) AS sid, id(endNode(r)) AS eid, type(r) AS t, properties(r) AS p;"],
        capture_output=True, text=True,
    )
    if rels.returncode != 0:
        sys.exit(f"rel dump failed: {rels.stderr}")
    (out_path.with_suffix(".rels.cypher")).write_text(rels.stdout, encoding="utf-8")

    total = out_path.with_suffix(".nodes.cypher").stat().st_size + out_path.with_suffix(".rels.cypher").stat().st_size
    print(f"Done      : {total/1024:.1f}KB (split .nodes + .rels)  ✓")


if __name__ == "__main__":
    main()
