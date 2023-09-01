import os
from ftplib import FTP


ftp_host = os.environ.get("FTP_HOST")
ftp_port = os.environ.get("FTP_PORT")
ftp_username = os.environ.get("FTP_USERNAME")
ftp_password = os.environ.get("FTP_PASSWORD")
ftp_directory = os.environ.get("FTP_DIRECTORY")



ftp = FTP()
ftp.connect(host=ftp_host, port=ftp_port)
ftp.login(user=ftp_username, passwd=ftp_password)
ftp.cwd(ftp_directory)

filename = 'example.txt'
local_file_path = f'downloaded_files/{filename}'

with open(local_file_path, 'wb') as file:
    ftp.retrbinary(f'RETR {filename}', file.write)

ftp.quit()