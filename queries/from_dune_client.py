import requests
import pandas as pd
import os
from dune_client.client import DuneClient
from datetime import datetime

# 使用你的 Dune API 密钥
API_KEY = "BBIZZhNA48tX06Ky8UMgDZ2V94oOUWcp"
DUNE_QUERY_ID = 4730817  # 替换为你想查询的 Dune 查询 ID

# 使用 DuneClient 获取查询结果
dune = DuneClient(API_KEY)
query_result = dune.get_latest_result(DUNE_QUERY_ID)

# 打印 query_result 对象以查看其结构
print(query_result)

# 提取结果行数据
rows = query_result.result.rows  # 直接使用 .rows 获取数据

# 将数据转换为 DataFrame
df = pd.DataFrame(rows)

# 获取列名信息
column_order = query_result.result.metadata.column_names
df = df[column_order]  # 按Dune的列顺序重新排列

# 获取桌面路径
desktop_path = os.path.expanduser('~/Desktop')

# 确保目录存在（一般桌面一定存在，但以防万一）
if not os.path.exists(desktop_path):
    os.makedirs(desktop_path)

# 使用当前时间生成唯一文件名
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
file_name = f'dune_query_result_{timestamp}.csv'

# 构造完整路径
file_path = os.path.join(desktop_path, file_name)

# 保存 DataFrame 为 CSV 文件
df.to_csv(file_path, index=False)

# 打印文件保存路径
print(f"数据已成功保存为 {file_path}")
