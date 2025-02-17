
import requests
import pandas as pd
import os
from dune_client.client import DuneClient

# 使用你的 Dune API 密钥
API_KEY = "BBIZZhNA48tX06Ky8UMgDZ2V94oOUWcp"
DUNE_QUERY_ID = 4730817  # 替换为你想查询的 Dune 查询 ID

# 使用 DuneClient 获取查询结果
dune = DuneClient(API_KEY)
query_result = dune.get_latest_result(DUNE_QUERY_ID)

# 提取结果行数据
rows = query_result.result.rows  # 直接使用 .rows 获取数据

# 将数据转换为 DataFrame
df = pd.DataFrame(rows)

# 获取桌面的路径
desktop_path = os.path.expanduser('~/Desktop')

# 构造保存文件的完整路径
file_path = os.path.join(desktop_path, 'dune_query_result.csv')

# 保存为 CSV 文件
df.to_csv(file_path, index=False)

print(f"数据已成功保存为 {file_path}")

