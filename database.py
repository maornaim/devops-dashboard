import os
import psycopg2


def get_connection():

    connection = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"]
    )

    return connection



def create_user(username, email):

    connection = get_connection()

    cursor = connection.cursor()

    cursor.execute(
        """
        INSERT INTO users (username, email)
        VALUES (%s, %s)
        """,
        (username, email)
    )

    connection.commit()

    cursor.close()
    connection.close()