-- HTTP Extension kontrolü
SELECT * FROM pg_available_extensions WHERE name = 'http';

-- HTTP Extension aktif mi?
SELECT extname, extversion FROM pg_extension WHERE extname = 'http';
