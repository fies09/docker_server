#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DEFAULT_CONTAINER = "ma-postgres"
DEFAULT_USER = "postgres"
DEFAULT_BACKUP_ROOT = "/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份"


def parse_args():
    p = argparse.ArgumentParser(description="PostgreSQL logical backup (pg_dump)")
    p.add_argument("--container", default=DEFAULT_CONTAINER)
    p.add_argument("--user", default=DEFAULT_USER)
    p.add_argument("--db", default=os.getenv("POSTGRES_DB", "my_assistant_db"))
    p.add_argument("--backup-root", default=DEFAULT_BACKUP_ROOT)
    p.add_argument("--output", default=None)
    return p.parse_args()


def main():
    args = parse_args()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = Path(args.output) if args.output else Path(args.backup_root) / f"postgres_{args.db}_{ts}.sql.gz"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Container : {args.container}")
    print(f"Database  : {args.db}")
    print(f"User      : {args.user}")
    print(f"Output    : {out_path}")

    cmd = [
        "docker", "exec", args.container,
        "pg_dump", "-U", args.user, "-d", args.db, "--no-owner", "--clean", "--if-exists",
    ]
    print(f"CMD       : {' '.join(cmd)} | gzip")
    with open(out_path, "wb") as f:
        p1 = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        p2 = subprocess.Popen(["gzip"], stdin=p1.stdout, stdout=f)
        p1.stdout.close()
        ret = p2.wait()
        p1.wait()
        if ret != 0:
            sys.exit(f"gzip failed: {ret}")
    size = out_path.stat().st_size
    print(f"Done      : {size/1024/1024:.1f}MB  ✓")


if __name__ == "__main__":
    main()
