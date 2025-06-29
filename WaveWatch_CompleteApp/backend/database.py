from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Your correct connection string with the updated password
correct_password = "08200108dyekrane"  # Your confirmed password

# Multiple connection string options with your correct credentials
DATABASE_URLS = [
    os.getenv("SUPABASE_DATABASE_URL"),
    os.getenv("DATABASE_URL"),
    # Your correct connection string
    f"postgresql://postgres.tlcbimopgpcaxgehncey:{correct_password}@aws-0-sa-east-1.pooler.supabase.com:6543/postgres",
   
]

# Filter out None values
DATABASE_URLS = [url for url in DATABASE_URLS if url]

print(f"🔗 Trying {len(DATABASE_URLS)} connection strings...")

# Try each connection string
engine = None
working_url = None

for i, url in enumerate(DATABASE_URLS):
    try:
        print(f"Trying connection {i+1}: {url[:70]}...")
        test_engine = create_engine(
            url,
            pool_pre_ping=True,
            pool_recycle=300,
            pool_size=2,
            max_overflow=5,
            echo=False,
            connect_args={"connect_timeout": 10}
        )
        
        # Test the connection
        with test_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        engine = test_engine
        working_url = url
        print(f"✅ Connection successful with URL {i+1}")
        break
        
    except Exception as e:
        print(f"❌ Connection {i+1} failed: {e}")
        continue

if engine is None:
    print("❌ All database connections failed. Running without database.")
    # Create a dummy engine for development
    engine = create_engine("sqlite:///./fallback.db")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def test_connection():
    """Test the database connection"""
    if engine is None:
        return False
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            return True
    except Exception as e:
        print(f"❌ Database connection test failed: {e}")
        return False

def get_connection_info():
    """Get information about the current database connection"""
    return {
        "working_url": working_url[:70] + "..." if working_url else None,
        "engine_available": engine is not None,
        "connection_test": test_connection()
    }
