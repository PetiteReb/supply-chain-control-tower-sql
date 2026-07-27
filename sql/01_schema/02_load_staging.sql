-- Charge le CSV brut DataCo dans staging.raw_orders
-- Prérequis (une fois, dans un terminal, à la racine du projet) :
--   docker cp "data/raw/DataCoSupplyChainDataset.csv" control_tower_db:/tmp/orders.csv
-- Puis exécuter ce fichier. ENCODING 'LATIN1' gère l'encodage ISO-8859-1 de la source.

TRUNCATE staging.raw_orders;

COPY staging.raw_orders
FROM '/tmp/orders.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');