from bs4 import BeautifulSoup
import pandas as pd
import requests
import nltk
from nltk.tag import pos_tag
from nltk.tokenize import word_tokenize
from sqlalchemy import create_engine, MetaData, Table, Column, text, Text, DateTime, ARRAY, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
import os 


def scrape_headline_dataset(url):
    # url = "https://www.bbc.com/news"

    response = requests.get(url, verify=False)
    soup = BeautifulSoup(response.text, 'html.parser')

    headlines = soup.find_all("h2")

    head_list = []
    for x in headlines:
        head_list.append(x.text.strip())
    df = pd.DataFrame({'headline':head_list})
    
    return df 

def data_cleaning(df):

    # Remove duplicates
    df_clean = df.copy()
    df_clean = df_clean.drop_duplicates()

    # Drop non-headline datasets
    df_clean["count_words"] = df_clean["headline"].str.split().str.len()
    df_clean = df_clean[df_clean["count_words"]> 3]
    df_clean = df_clean.drop(columns = "count_words")

    # Data Cleaning to extract common keywords

    # Download nltk packages 
    nltk.download('punkt')
    nltk.download('averaged_perceptron_tagger')
    
    # Word Tokenize
    df_clean["tokens"] = df_clean["headline"].apply(word_tokenize)

    # Extract Nouns and Verbs
    df_clean["tokens"] = df_clean["tokens"].apply(lambda x: 
                                                  [word for (word, pos) in pos_tag(x) if pos in 
                                                   ["NN", "NNS", "NNP", "NNPS", 
                                                    'VB', 'VBG', 'VBD', 'VBN']])
    
    # Add etl date information
    df_clean["etl_date"] = pd.to_datetime('today')
    df_clean["etl_date"] = df_clean["etl_date"].dt.normalize()

    return df_clean

def write_postgres(df):

    # Connect and write to postgresql docker
    db_host = os.getenv("DB_HOST", "localhost") 
    db_user = os.getenv("POSTGRES_USER", "postgres")
    db_password = os.getenv("POSTGRES_PASSWORD", "postgres")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("POSTGRES_NAME", "postgres")
    
    engine = create_engine(f'postgresql+psycopg2://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}')
    
    # Create the table if it does not exist 
    # Implement a unique contraint on the headline text to avoid duplication of data
    metadata = MetaData()
    Table(
        'bbc',
        metadata,
        Column('headline', Text, nullable=False),
        Column('tokens', PG_ARRAY(Text)),
        Column('etl_date', DateTime),
        UniqueConstraint('headline', name='unique_headline') 
    )
    metadata.create_all(engine)

    with engine.begin() as connection:
        for _, row in df.iterrows():
            stmt = text("""
                INSERT INTO bbc (headline, tokens, etl_date)
                VALUES (:headline, :tokens, :etl_date)
                ON CONFLICT (headline) DO NOTHING;
            """)
            connection.execute(stmt, {
            "headline": row["headline"],
            "tokens": row["tokens"],
            "etl_date": row["etl_date"]
            })
    
    # Close the connection 
    engine.dispose()

def main():
    url = "https://www.bbc.com/news"
    df = scrape_headline_dataset(url)
    df_clean = data_cleaning(df)
    write_postgres(df_clean)

if __name__ == '__main__':
    main()