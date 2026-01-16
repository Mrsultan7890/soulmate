import aiosqlite
import asyncio

async def check():
    db = await aiosqlite.connect('soulmate.db')
    cursor = await db.execute('SELECT id, name, fcm_token FROM users LIMIT 5')
    rows = await cursor.fetchall()
    print("Users and their FCM tokens:")
    for row in rows:
        print(f"ID: {row[0]}, Name: {row[1]}, FCM Token: {row[2]}")
    await db.close()

asyncio.run(check())
