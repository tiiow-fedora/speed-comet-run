"""Rough economy sim: greedy player who runs, farms laps when blocked, buys best boots, rebirths when allowed."""
import math
G,H=80,16; T=2*math.sqrt(2*G*H)/G
req=[25,75,200,500,1200,3000,7500,18000,45000,100000]
wins=[5,10,25,60,150,400,1000,2500,6000,15000]
boots=[(1,0),(2,50),(4,300),(8,1500),(16,7500),(32,35000)]
def ws(s): return min(140,16+12*math.log(1+s/5))
# stage geometry (mirror MapBuilder)
z=40; pads=[]; gates=[]
for i in range(1,11):
    prev=req[i-2] if i>1 else 0
    gap=min(45,max(8,ws(prev)*T*0.5))
    z+=60+8*i; isl=22+i
    z+=2*(gap+isl)+gap; z+=70+10*i
    gates.append(z-6); padlen=70 if i==10 else 50; pads.append(z+25); z+=padlen
spawn=-20
def sim(mult_pass=1.0, horizon=4*3600):
    t=0; speed=0; w=0; boot=0; reb=0; reached=0; marks={}
    pos=spawn; claimed=set()
    while t<horizon and reached<10:
        m=boots[boot][0]*(1+reb)*mult_pass
        # next target
        n=len(claimed)
        if n<10 and speed>=req[n]:
            d=pads[n]-pos; dt=max(1,d/ws(speed)); t+=dt; speed+=m*dt; pos=pads[n]
            claimed.add(n); w+=wins[n]
            if n+1>reached:
                reached=n+1; marks[reached]=t
            if n==9: claimed=set(); pos=spawn
        else:
            # blocked: farm a lap if it pays, else wait
            if n>0 and n<10:
                d=pads[n-1]-spawn; dt=d/ws(speed)+2; 
                # restart lap and re-run claimed pads
                t+=dt; speed+=m*dt; w+=sum(wins[:n]); pos=pads[n-1]
            else:
                t+=5; speed+=m*5
        for b in range(len(boots)-1,boot,-1):
            if w>=boots[b][1]: w-=boots[b][1]; boot=b; break
    return marks
for label,mp in [("free",1),("2x pass",2)]:
    mk=sim(mp); print(label, {k:f"{v/60:.1f}m" for k,v in mk.items()})
print("gate Z:",[round(g) for g in gates])
