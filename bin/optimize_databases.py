import os
import sqlite3

def optimize_pokedex(db_path):
    print(f"\n==========================================")
    print(f"Optimizing {db_path}...")
    size_before = os.path.getsize(db_path)
    
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # 1. Create full covering indexes
    c.execute("DROP INDEX IF EXISTS idx_dex_orders_poke_dex;")
    c.execute("CREATE INDEX idx_dex_orders_poke_dex ON dex_orders (pokemon_id, dex_name, order_index);")
    c.execute("CREATE INDEX IF NOT EXISTS idx_special_dexes_poke_dex ON special_dexes (pokemon_id, dex_name);")
    print("  -> Created indexes idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index) and idx_special_dexes_poke_dex")
    
    # 2. ANALYZE
    c.execute("ANALYZE;")
    print("  -> Executed ANALYZE")
    
    # 3. PRAGMA optimize
    c.execute("PRAGMA optimize;")
    print("  -> Executed PRAGMA optimize")
    
    conn.commit()
    
    # 4. Integrity check
    c.execute("PRAGMA integrity_check;")
    integrity = c.fetchone()[0]
    print(f"  -> Integrity check: {integrity}")
    assert integrity == "ok", f"Integrity check failed: {integrity}"
    
    # 5. Explain query plan verification
    c.execute("EXPLAIN QUERY PLAN SELECT * FROM dex_orders WHERE pokemon_id = 25 AND dex_name = 'hisui_regional';")
    plan_dex = [row[3] for row in c.fetchall()]
    print(f"  -> EQP dex_orders (SELECT *): {' '.join(plan_dex)}")
    assert any("COVERING INDEX" in p and "idx_dex_orders_poke_dex" in p for p in plan_dex), "EQP did not use COVERING INDEX idx_dex_orders_poke_dex!"
    
    c.execute("EXPLAIN QUERY PLAN SELECT * FROM special_dexes WHERE pokemon_id = 25 AND dex_name = 'legendary-dex';")
    plan_special = [row[3] for row in c.fetchall()]
    print(f"  -> EQP special_dexes (SELECT *): {' '.join(plan_special)}")
    assert any("COVERING INDEX" in p and "idx_special_dexes_poke_dex" in p for p in plan_special), "EQP did not use COVERING INDEX idx_special_dexes_poke_dex!"
    
    # 6. Check sqlite_stat1
    c.execute("SELECT count(*) FROM sqlite_stat1 WHERE tbl IN ('dex_orders', 'special_dexes');")
    stat_count = c.fetchone()[0]
    print(f"  -> sqlite_stat1 rows for target tables: {stat_count}")
    
    conn.close()
    
    size_after = os.path.getsize(db_path)
    print(f"  -> Size before: {size_before:,} bytes | after: {size_after:,} bytes")

def vacuum_user_data(db_path):
    print(f"\n==========================================")
    print(f"Vacuuming {db_path}...")
    size_before = os.path.getsize(db_path)
    
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # 1. VACUUM
    c.execute("VACUUM;")
    print("  -> Executed VACUUM")

    # 2. Checkpoint & truncate WAL
    try:
        c.execute("PRAGMA wal_checkpoint(TRUNCATE);")
        print("  -> Executed PRAGMA wal_checkpoint(TRUNCATE)")
    except Exception as e:
        print(f"  -> WAL checkpoint notice: {e}")
    
    # 3. Integrity check
    c.execute("PRAGMA integrity_check;")
    integrity = c.fetchone()[0]
    print(f"  -> Integrity check: {integrity}")
    assert integrity == "ok", f"Integrity check failed: {integrity}"
    
    conn.close()
    
    size_after = os.path.getsize(db_path)
    print(f"  -> Size before: {size_before:,} bytes | after: {size_after:,} bytes")

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets_pokedex = os.path.join(base_dir, "assets", "db", "pokedex.sqlite")
    dev_pokedex = os.path.join(base_dir, "database", "pokedex.sqlite")
    user_data = os.path.join(base_dir, "database", "user_data.sqlite")
    
    if os.path.exists(assets_pokedex):
        optimize_pokedex(assets_pokedex)
    else:
        print(f"Warning: {assets_pokedex} not found")
        
    if os.path.exists(dev_pokedex):
        optimize_pokedex(dev_pokedex)
    else:
        print(f"Warning: {dev_pokedex} not found")
        
    if os.path.exists(user_data):
        vacuum_user_data(user_data)
    else:
        print(f"Warning: {user_data} not found")
        
    print("\nAll database optimizations and maintenance finished successfully!")

if __name__ == "__main__":
    main()
