import sqlite3

# 1. Connect to the database. 
# (If 'app.db' doesn't exist yet, Python will create it automatically!)
connection = sqlite3.connect("app.db")

# 2. Create a "cursor". Think of this as the messenger that carries our SQL to the database.
cursor = connection.cursor()

# 3. Execute the exact SQL you just learned
cursor.execute("""
CREATE TABLE IF NOT EXISTS snippets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    code_block TEXT NOT NULL,
    tag TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""")

# 4. Save the changes and close the connection
connection.commit()
connection.close()

print("Database and 'snippets' table created successfully!")