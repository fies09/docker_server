#!/usr/bin/env python3
from neo4j import GraphDatabase
from neo4j.time import DateTime
import json
import os
from datetime import datetime

NEO4J_HOST = os.environ.get("NEO4J_HOST", "localhost")
NEO4J_PORT = os.environ.get("NEO4J_PORT", "7687")
NEO4J_USER = os.environ.get("NEO4J_USER", "neo4j")

def _load_password():
    env_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                if line.startswith("NEO4J_PASSWORD="):
                    return line.strip().split("=", 1)[1]
    return os.environ.get("NEO4J_PASSWORD", "")

NEO4J_PASSWORD = _load_password()
NEO4J_URI = f"bolt://{NEO4J_HOST}:{NEO4J_PORT}"

# 导出配置
BATCH_SIZE = 1000
OUTPUT_DIR = "./neo4j_export"

class Neo4jExporter:
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self.driver.close()

    def export_nodes(self, output_file):
        with self.driver.session() as session:
            offset = 0
            total = 0

            with open(output_file, 'w', encoding='utf-8') as f:
                while True:
                    result = session.run(
                        "MATCH (n) RETURN n SKIP $offset LIMIT $limit",
                        offset=offset, limit=BATCH_SIZE
                    )

                    batch = []
                    for record in result:
                        node = record["n"]
                        props = {}
                        for k, v in dict(node).items():
                            if isinstance(v, DateTime):
                                props[k] = v.iso_format()
                            else:
                                props[k] = v
                        batch.append({
                            "id": node.id,
                            "labels": list(node.labels),
                            "properties": props
                        })

                    if not batch:
                        break

                    for item in batch:
                        f.write(json.dumps(item, ensure_ascii=False) + '\n')

                    total += len(batch)
                    offset += BATCH_SIZE
                    print(f"已导出 {total} 个节点...")

            print(f"节点导出完成，共 {total} 个")

    def export_relationships(self, output_file):
        with self.driver.session() as session:
            offset = 0
            total = 0

            with open(output_file, 'w', encoding='utf-8') as f:
                while True:
                    result = session.run(
                        "MATCH (a)-[r]->(b) RETURN id(a) as start_id, type(r) as type, properties(r) as props, id(b) as end_id SKIP $offset LIMIT $limit",
                        offset=offset, limit=BATCH_SIZE
                    )

                    batch = []
                    for record in result:
                        batch.append({
                            "start_id": record["start_id"],
                            "type": record["type"],
                            "properties": record["props"],
                            "end_id": record["end_id"]
                        })

                    if not batch:
                        break

                    for item in batch:
                        f.write(json.dumps(item, ensure_ascii=False) + '\n')

                    total += len(batch)
                    offset += BATCH_SIZE
                    print(f"已导出 {total} 个关系...")

            print(f"关系导出完成，共 {total} 个")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    nodes_file = os.path.join(OUTPUT_DIR, f"nodes_{timestamp}.jsonl")
    rels_file = os.path.join(OUTPUT_DIR, f"relationships_{timestamp}.jsonl")

    print(f"开始导出Neo4j数据 ({NEO4J_URI})...")
    exporter = Neo4jExporter(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD)

    try:
        print("\n导出节点...")
        exporter.export_nodes(nodes_file)

        print("\n导出关系...")
        exporter.export_relationships(rels_file)

        print(f"\n导出完成！")
        print(f"节点文件: {nodes_file}")
        print(f"关系文件: {rels_file}")
    finally:
        exporter.close()

if __name__ == "__main__":
    main()
