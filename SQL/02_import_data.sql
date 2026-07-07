

begin;
truncate raw_col;
\copy raw_col from 'output/tables/colors.csv' delimiter ',' csv header;
commit;

