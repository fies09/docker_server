#!/usr/bin/env python3
from neo4j import GraphDatabase
import json
import sys

# 本地Neo4j配置
LOCAL_URI = "bolt://localhost:7687"
LOCAL_USER = "neo4j"
LOCAL_PASSWORD = "12345678"

BATCH_SIZE = 500

class Neo4jImporter:
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self.driver.close()

    def import_nodes(self, nodes_file):
        with self.driver.session() as session:
            batch = []
            total = 0

            with open(nodes_file, 'r', encoding='utf-8') as f:
                for line in f:
                    node = json.loads(line)
                    batch.append(node)

                    if len(batch) >= BATCH_SIZE:
                        self._create_nodes_batch(session, batch)
                        total += len(batch)
                        print(f"已导入 {total} 个节点...")
                        batch = []

                if batch:
                    self._create_nodes_batch(session, batch)
                    total += len(batch)

            print(f"节点导入完成，共 {total} 个")

    def _create_nodes_batch(self, session, nodes):
        session.run("""
            UNWIND $nodes AS node
            CALL apoc.create.node(node.labels, node.properties) YIELD node AS n
            RETURN count(n)
        """, nodes=nodes)

    def import_relationships(self, rels_file):
        with self.driver.session() as session:
            batch = []
            total = 0

            with open(rels_file, 'r', encoding='utf-8') as f:
                for line in f:
                    rel = json.loads(line)
                    batch.append(rel)

                    if len(batch) >= BATCH_SIZE:
                        self._create_rels_batch(session, batch)
                        total += len(batch)
                        print(f"已导入 {total} 个关系...")
                        batch = []

                if batch:
                    self._create_rels_batch(session, batch)
                    total += len(batch)

            print(f"关系导入完成，共 {total} 个")

    def _create_rels_batch(self, session, rels):
        session.run("""
            UNWIND $rels AS rel
            MATCH (a), (b)
            WHERE id(a) = rel.start_id AND id(b) = rel.end_id
            CALL apoc.create.relationship(a, rel.type, rel.properties, b) YIELD rel AS r
            RETURN count(r)
        """, rels=rels)

def main():
    if len(sys.argv) != 3:
        print("用法: python import_neo4j.py <nodes_file> <relationships_file>")
        sys.exit(1)

    nodes_file = sys.argv[1]
    rels_file = sys.argv[2]

    print("开始导入到本地Neo4j...")
    importer = Neo4jImporter(LOCAL_URI, LOCAL_USER, LOCAL_PASSWORD)

    try:
        print("\n导入节点...")
        importer.import_nodes(nodes_file)

        print("\n导入关系...")
        importer.import_relationships(rels_file)

        print("\n导入完成！")
    finally:
        importer.close()

if __name__ == "__main__":
    main()
