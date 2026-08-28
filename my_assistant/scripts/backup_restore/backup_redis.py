#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DEFAULT_CONTAINER = "ma-redis"
DEFAULT_PASSWORD = "redis123"
DEFAULT_BACKUP_ROOT = "/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份"


def parse_args():
    p = argparse.ArgumentParser(description="Redis RDB snapshot via docker exec")
    p.add_argument("--container", default=DEFAULT_CONTAINER)
    p.add_argument("--password", default=os.getenv("REDIS_PASSWORD", DEFAULT_PASSWORD))
    p.add_argument("--backup-root", default=DEFAULT_BACKUP_ROOT)
    p.add_argument("--output", default=None)
    return p.parse_args()


def main():
    args = parse_args()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = Path(args.output) if args.output else Path(args.backup_root) / f"redis_{ts}.rdb"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Container : {args.container}")
    print(f"Output    : {out_path}")

    exec_cmd = [
        "docker", "exec", args.container,
        "sh", "-c",
        f"redis-cli -a '{args.password}' --no-auth-warning BGSAVE && "
        f"while [ \"$(redis-cli -a '{args.password}' --no-auth-warning LASTSAVE)\" = \"$(cat /tmp/redis_lastsave 2>/dev/null)\" ]; do sleep 0.2; done; "
        f"redis-cli -a '{args.password}' --no-auth-warning LASTSAVE > /tmp/redis_lastsave && "
        f"cat /data/dump.rdb",
    ]
    print(f"CMD       : {' '.join(exec_cmd)}")
    with open(out_path, "wb") as f:
        ret = subprocess.run(exec_cmd, stdout=f, stderr=subprocess.PIPE)
        if ret.returncode != 0:
            sys.exit(f"redis backup failed: {ret.stderr.decode()}")

    size = out_path.stat().st_size
    print(f"Done      : {size/1024:.1f}KB  ✓")


if __name__ == "__main__":
    main()
