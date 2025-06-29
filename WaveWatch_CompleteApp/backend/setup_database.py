from database_manager import db_manager
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Main setup function"""
    print("🚀 Starting database setup...")
    
    try:
        # Safe database initialization
        success = db_manager.safe_initialize_database()
        
        if success:
            print("\n📊 Database Information:")
            db_info = db_manager.get_database_info()
            
            print(f"Connection Status: {db_info['connection_status']}")
            print(f"Existing Tables: {db_info['existing_tables']}")
            
            for table_name, details in db_info['table_details'].items():
                print(f"\n📋 Table: {table_name}")
                print(f"  Columns: {details['columns']}")
                schema_info = details['schema_info']
                if schema_info.get('schema_match'):
                    print(f"  Schema: ✅ Up to date")
                else:
                    print(f"  Schema: ⚠️ Needs attention")
                    if schema_info.get('missing_columns'):
                        print(f"  Missing columns: {schema_info['missing_columns']}")
            
            print("\n🎉 Database setup completed successfully!")
        else:
            print("❌ Database setup failed!")
            
    except Exception as e:
        print(f"❌ Setup error: {e}")

if __name__ == "__main__":
    main()
