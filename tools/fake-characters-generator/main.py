import re
import pandas as pd
from faker import Faker
from collections import defaultdict
from sqlalchemy import create_engine


conn_string = "mysql://root:root@localhost/acore_eluna"
guid_start = 10000
account_start = 1
account_end = 100
max_level = 70
n_rows = 5_000

classes = (1, 2, 3, 4, 5, 7, 8, 9, 11)
races = (1, 2, 3, 4, 5, 6, 7, 8, 10, 11)

fake = Faker()
fake_data = defaultdict(list)


for i in range(n_rows):
    fake_data["guid"].append(guid_start + i)
    fake_data["account"].append(fake.random_int(account_start, account_end))
    gender = fake.random_int(0, 1)
    name = ""
    while True:
        if gender == 0:
            name = fake.first_name_male()
        else:
            name = fake.first_name_female()
        if len(name) <= 12 and re.search("^[A-Z][a-z]*$", name) is not None:
            break
    fake_data["name"].append(name)
    fake_data["race"].append(fake.random_element(elements=races))
    fake_data["class"].append(fake.random_element(elements=classes))
    fake_data["gender"].append(gender)
    level = fake.random_int(1, max_level)
    fake_data["level"].append(level)
    challenge = fake.random_int(1, 7)
    fake_data["challenge"].append(challenge)
    dead = False
    if level == max_level:
        fake_data["completed"].append(1)
    else:
        fake_data["completed"].append(0)
        if challenge in [1, 3, 5, 7]: # challenges with hardcore mode
            dead = fake.pybool()
    if dead:
        fake_data["dead"].append(1)
        fake_data["died_on"].append(0)
        fake_data["char_deleted"].append(1)
    else:
        fake_data["dead"].append(0)
        fake_data["died_on"].append(None)
        fake_data["char_deleted"].append(0)
    fake_data["played_time"].append(int(fake.pyfloat(min_value=5, max_value=20) * pow(float(level), 2)))

df_fake_data = pd.DataFrame(fake_data)
engine = create_engine(conn_string, echo=False)
df_fake_data.to_sql("challenge_modes_character", con=engine, if_exists="append", index=False)
