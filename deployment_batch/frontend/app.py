import matplotlib.pyplot as plt
from nltk import FreqDist
import pandas as pd
import psycopg2
import streamlit as st
import os 
from wordcloud import WordCloud

def form_connection():

    # Connect to PostgreSQL
    db_host = os.getenv("DB_HOST", "localhost") 
    db_user = os.getenv("POSTGRES_USER", "postgres")
    db_password = os.getenv("POSTGRES_PASSWORD", "postgres")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("POSTGRES_NAME", "postgres")

    conn = psycopg2.connect(
        database = db_name,
        user = db_user,
        password = db_password ,
        host = db_host,
        port = db_port
        )
    cursor = conn.cursor()

    return conn, cursor

def extract_dataset(conn, cursor):
    
    # Extract the recent dataset from PostgreSQL 
    sql = "SELECT * FROM bbc WHERE etl_date::date >= current_date - INTERVAL '2 DAYS';"
    cursor.execute(sql)
    query_output = cursor.fetchall()
    # Convert to a pandas dataframe 
    df = pd.DataFrame(query_output, columns=['headline', 'tokens', 'etl_date'])
    print(df.info())
    # Close the connection 
    cursor.close()
    conn.close()

    return df 

def _helper_check_most_freq(x, most_freq_keywords):

    if any(i in most_freq_keywords for i in x):
        return True
    
    return False

def data_preparation_for_visualisation(df_clean, x_frequent, y_wordcloud):

    # Frequency distribution of all the tokens
    keyword_list = df_clean["tokens"].sum()
    keyword_freqdist = FreqDist(keyword_list) 

    # Extract the top x most frequent keywords 
    most_freq_keywords = dict(keyword_freqdist.most_common(x_frequent))
    most_freq_keywords = list(most_freq_keywords.keys())

    # Extract the corresponding headline of the top 3 most frequent keywords 
    df_headline = df_clean.loc[df_clean.apply(lambda x: _helper_check_most_freq(x['tokens'], most_freq_keywords ), axis = 1), 'headline']
    df_headline = df_headline.reset_index(drop=True)

    # Prepare the dictinary to feed into wordcloud
    keyword_wordcloud = dict(keyword_freqdist.most_common(y_wordcloud))
    
    return df_headline, keyword_wordcloud 

# Get the dataset 
conn, cursor = form_connection()
df_clean_all = extract_dataset(conn, cursor)
df_clean = df_clean_all.copy()

max_date = df_clean["etl_date"].max()
st.title("News Headline Overview")
st.write("Last Updated" , max_date.date())

y_wordcloud = st.number_input("Insert a number for the wordcloud of the top most frequent keywords", 
                              value = 12)
x_frequent =  st.number_input("Insert a number for the headline of the top most frequent keywords", 
                              value = 3)

# Prepare the dataset based on user inputs 
df_headline, keyword_wordcloud = data_preparation_for_visualisation(df_clean, 
                                                                 x_frequent, 
                                                                 y_wordcloud)
# Generate the wordcloud image 
wordcloud = WordCloud().generate_from_frequencies(keyword_wordcloud)

# Display the wordcloud image:
fig, ax = plt.subplots(figsize = (12, 8))
ax.imshow(wordcloud)
plt.axis('off')
st.pyplot(fig)
st.write("Wordcloud of the top" , y_wordcloud, " most frequent keywords")

st.table(df_headline)
st.write("Headline of the top" , x_frequent, " most frequent keywords")

# streamlit run app.py

