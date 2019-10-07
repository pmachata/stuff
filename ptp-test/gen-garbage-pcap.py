import sys
import struct

if False:
    from scapy import route
    from scapy.config import conf
    from scapy.layers.l2 import Ether
    from scapy.layers.inet import IP, UDP
    from scapy.packet import Raw
    from scapy.sendrecv import sendpfast

    def genpkt(msgt, cdom, seq1, seq2):
        return (Ether(dst="ff:ff:ff:ff:ff:ff") /
                IP(src="192.0.2.1",
                dst="224.0.1.129") /
                UDP(sport=319, dport=319) /
                Raw(load=bytearray([msgt, 0x02, 0x00, 0x00,
                                    cdom, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, seq1, seq2,
                                    0x00, 0x00])))
    conf.iface = "sw1p5"

    packets = list(genpkt(msgt, cdom, 0, seq)
                for seq in range(100)
                for msgt in range(4)
                for cdom in range(25))
    print(len(packets))
    #sendpfast(packets, iface="sw1p5")

    sys.exit(1)

def flatten(l):
    ret = []
    for item in l:
        if type(item) is list:
            ret += flatten(item)
        else:
            ret.append(item)
    return ret

class Checksum: pass
class Length: pass

def expand(packet, token, replacement):
    i = packet.index(token)
    packet[i:i+1] = replacement
    return packet

def word(n):
    assert n <= 0xffff
    assert n >= 0
    return [n >> 8, n & 0xff]

def fmt(octets):
    print(":".join(hex(i)[2:] for i in octets))

def checksum_ipv4(packet):
    packet[:] = flatten(packet)
    octets = list(i for i in packet if i is not Checksum)
    cksum = sum((a<<8) + b for a, b in zip(octets[::2], octets[1::2]))
    cksum = (cksum & 0xffff) + (cksum >> 16) # add carry
    cksum = (cksum & 0xffff) + (cksum >> 16) # add carry again
    cksum = cksum ^ 0xffff
    expand(packet, Checksum, word(cksum))

def source_mac():
    return [0x7c, 0xfe, 0x90, 0xf5, 0xa3, 0x79] # xxx

def genpkt(msgt, cdom, seq):
    bc_mac = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
    ethtype_ipv4 = [0x08, 0x00]
    eth_header = [bc_mac, source_mac(), ethtype_ipv4]

    ttl = 255
    proto_udp = 17
    sip = [192, 0, 2, 1]
    dip = [224, 0, 1, 129]
    ipv4_header = [
        0x45, 0x00, 0x00, 0x3e,     # u4 version, u4 IHL, u8, TOS, u16 length
        0x00, 0x00, 0x00, 0x00,     # u16 identification, flags, fragment off
        ttl, proto_udp, Checksum, sip, dip]
    checksum_ipv4(ipv4_header)

    sport = word(319)
    dport = sport
    udp_header = [sport, dport, Length, Checksum]
    payload = flatten([msgt, 0x02, 0x00, 0x00,
                       cdom, 0x00, 0x00, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0x00, word(seq),
                       0x00, 0x00])
    expand(udp_header, Length, word(len(payload) + 8))
    expand(udp_header, Checksum, word(0))

    return flatten([eth_header, ipv4_header, udp_header, payload])

packets = list(genpkt(msgt, cdom, seq)
               for seq in range(100)
               for msgt in range(4)
               for cdom in range(25))

#fmt(packet)

def pcap_header_out(f = sys.stdout):
    LINKTYPE_ETHERNET = 1
    pcap_header = struct.pack("IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 0xffff,
                              LINKTYPE_ETHERNET)
    f.write(pcap_header)
    f.flush()

def pcap_packet_header(secs, usecs, pktlen):
    return struct.pack("IIII", secs, usecs, pktlen, pktlen)

out = sys.stdout
pcap_header_out(out)
for packet in packets:
    out.write(pcap_packet_header(0, 0, len(packet)))
    out.write(bytearray(packet))
out.flush()
