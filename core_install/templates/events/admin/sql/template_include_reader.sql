IF (SELECT 1 FROM sp_iqmpxinfo() WHERE SERVER_NAME = '@@reader_name@@' AND STATUS = 'excluded') = 1
BEGIN
    ALTER MULTIPLEX SERVER @@reader_name@@ STATUS INCLUDED
END
