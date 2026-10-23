"""Download only the Web template from the official Godot template ZIP using HTTP ranges.
Avoids fetching the complete multi-platform bundle (over 1 GB).
"""
from pathlib import Path
import binascii
import struct
import urllib.request
import zlib

VERSION = '4.7.2-stable'
URL = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}/Godot_v{VERSION}_export_templates.tpz'
DEST = Path(__file__).resolve().parents[1] / '.runtime/templates'

def read_range(start, end=None):
    value = f'bytes={start}-{end}' if end is not None else f'bytes={start}'
    req = urllib.request.Request(URL, headers={'Range': value, 'User-Agent': 'Astro-Web-Export'})
    with urllib.request.urlopen(req, timeout=90) as response:
        if response.status != 206:
            raise RuntimeError('Server does not support partial downloads. Install official export templates in Godot instead.')
        return response.read(), response.headers.get('Content-Range')

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    _, content_range = read_range(0, 0)
    total = int(content_range.split('/')[-1])
    tail, _ = read_range(total-131072, total-1)
    eocd = tail.rfind(b'PK\x05\x06')
    if eocd < 0: raise RuntimeError('Missing ZIP directory')
    header = struct.unpack_from('<4s4H2IH', tail, eocd)
    size, offset = header[5:7]
    central = tail[offset-(total-len(tail)):offset-(total-len(tail))+size] if offset >= total-len(tail) else read_range(offset, offset+size-1)[0]
    pos=0
    while pos < len(central):
        row=struct.unpack_from('<4s6H3I5H2I',central,pos)
        if row[0] != b'PK\x01\x02': raise RuntimeError('Invalid ZIP entry')
        name=central[pos+46:pos+46+row[10]].decode('utf-8')
        if name.endswith('/web_nothreads_release.zip'):
            local=read_range(row[16],row[16]+29)[0]
            fnlen, extralen=struct.unpack_from('<2H',local,26)
            start=row[16]+30+fnlen+extralen
            data=read_range(start,start+row[8]-1)[0]
            if row[4]==8: data=zlib.decompress(data,-15)
            elif row[4]!=0: raise RuntimeError('Unsupported ZIP method')
            if len(data)!=row[9] or binascii.crc32(data)!=row[7]: raise RuntimeError('ZIP checksum mismatch')
            target=DEST/'web_nothreads_release.zip'
            target.write_bytes(data)
            print(f'Official {VERSION} Web template: {target} ({len(data)} bytes, CRC verified)')
            return
        pos += 46+row[10]+row[11]+row[12]
    raise RuntimeError('Web template absent from release bundle')

if __name__=='__main__': main()
