select * 
from dune.hildobby.dataset_bitcoin_etf_addresses 
limit 100;

COPY (
    SELECT * FROM dune.hildobby.dataset_bitcoin_etf_addresses 
) TO '/tmp/dune_data.csv' WITH CSV HEADER;
