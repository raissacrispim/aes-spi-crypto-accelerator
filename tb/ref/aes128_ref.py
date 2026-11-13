# Modelo de referencia AES-128 (FIPS-197), escrito de forma independente do RTL.
#
# Uso:
#   python3 tb/ref/aes128_ref.py
#
# Confere os vetores dos Apendices B e C.1 da FIPS-197, imprime as round keys
# dos Apendices A.1 e C.1 e gera os vetores adicionais (chave, plaintext,
# ciphertext) usados em tb/minisoc_aes_dp_tb.sv (semente fixa 2026).
def xt(a): return ((a<<1)^0x1b)&0xff if a&0x80 else a<<1
def gmul(a,b):
    r=0
    while b:
        if b&1: r^=a
        a=xt(a); b>>=1
    return r
def inv(a):
    if a==0: return 0
    for b in range(1,256):
        if gmul(a,b)==1: return b
def sbox_calc(x):
    b=inv(x); r=0x63
    for i in range(5): r^=((b<<i)|(b>>(8-i)))&0xff
    return r
SB=[sbox_calc(x) for x in range(256)]
ISB=[0]*256
for i,v in enumerate(SB): ISB[v]=i
h=lambda s: bytes(s).hex()
def sub(s): return [SB[b] for b in s]
def isub(s): return [ISB[b] for b in s]
def shift(s): return [s[(n%4)+4*(((n//4)+(n%4))%4)] for n in range(16)]
def ishift(s): return [s[(n%4)+4*(((n//4)-(n%4))%4)] for n in range(16)]
def mix(s):
    o=[]
    for c in range(4):
        a=s[4*c:4*c+4]
        o+=[gmul(a[0],2)^gmul(a[1],3)^a[2]^a[3], a[0]^gmul(a[1],2)^gmul(a[2],3)^a[3],
            a[0]^a[1]^gmul(a[2],2)^gmul(a[3],3), gmul(a[0],3)^a[1]^a[2]^gmul(a[3],2)]
    return o
def imix(s):
    o=[]
    for c in range(4):
        a=s[4*c:4*c+4]
        o+=[gmul(a[0],14)^gmul(a[1],11)^gmul(a[2],13)^gmul(a[3],9), gmul(a[0],9)^gmul(a[1],14)^gmul(a[2],11)^gmul(a[3],13),
            gmul(a[0],13)^gmul(a[1],9)^gmul(a[2],14)^gmul(a[3],11), gmul(a[0],11)^gmul(a[1],13)^gmul(a[2],9)^gmul(a[3],14)]
    return o
def ark(s,k): return [a^b for a,b in zip(s,k)]
def keyexp(key):
    w=[key[4*i:4*i+4] for i in range(4)]; rc=1
    for i in range(4,44):
        t=list(w[i-1])
        if i%4==0:
            t=t[1:]+t[:1]; t=[SB[b] for b in t]; t[0]^=rc; rc=xt(rc)
        w.append([a^b for a,b in zip(w[i-4],t)])
    return [sum(w[4*r:4*r+4],[]) for r in range(11)]
def enc(pt,key):
    rk=keyexp(key); s=ark(pt,rk[0])
    for r in range(1,11):
        s=shift(sub(s))
        if r<10: s=mix(s)
        s=ark(s,rk[r])
    return s
def dec(ct,key):
    rk=keyexp(key); s=ark(ct,rk[10])
    for r in range(9,-1,-1):
        s=isub(ishift(s)); s=ark(s,rk[r])
        if r>0: s=imix(s)
    return s
if __name__=="__main__":
    import random
    B=lambda x: list(bytes.fromhex(x))
    assert h(enc(B('3243f6a8885a308d313198a2e0370734'),B('2b7e151628aed2a6abf7158809cf4f3c')))=='3925841d02dc09fbdc118597196a0b32'
    assert h(enc(B('00112233445566778899aabbccddeeff'),B('000102030405060708090a0b0c0d0e0f')))=='69c4e0d86a7b0430d8cdb78070b4c55a'
    print("FIPS-197 ok")
    print("rkB", [h(k) for k in keyexp(B('2b7e151628aed2a6abf7158809cf4f3c'))])
    print("rkC", [h(k) for k in keyexp(B('000102030405060708090a0b0c0d0e0f'))])
    rnd=random.Random(2026)
    for i in range(8):
        k=[rnd.randrange(256) for _ in range(16)]; p=[rnd.randrange(256) for _ in range(16)]
        c=enc(p,k); assert dec(c,k)==p
        print(f"V {h(k)} {h(p)} {h(c)}")
