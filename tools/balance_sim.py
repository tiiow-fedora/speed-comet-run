"""Rough economy sim: greedy player who runs, farms laps when blocked, buys best boots, rebirths when allowed."""
import math
G,H=80,16; T=2*math.sqrt(2*G*H)/G
req=[25,75,200,500,1200,3000,7500,18000,45000,100000,220000,500000,1100000,2500000,6000000]
wins=[5,10,25,60,150,400,1000,2500,6000,15000,35000,80000,180000,400000,1000000]
boots=[(1,0),(2,50),(4,300),(8,1500),(16,7500),(32,35000),(64,175000),(128,900000)]
def ws(s): return min(140,16+12*math.log(1+s/5))
# stage geometry (mirror MapBuilder)
z=40; pads=[]; gates=[]
for i in range(1,len(req)+1):
    prev=req[i-2] if i>1 else 0
    gap=min(45,max(8,ws(prev)*T*0.5))
    z+=60+8*i; isl=22+i
    z+=2*(gap+isl)+gap; z+=70+10*i
    gates.append(z-6); padlen=70 if i==len(req) else 50; pads.append(z+25); z+=padlen
spawn=-20
# v4 companions (mirror Config.Companions): (Speed gain bonus, Wins cost); one equipped, buy order by value per cost
pets=[(0.10,100),(0.25,800),(0.50,5000),(1.00,30000),(2.00,200000)]
def sim(mult_pass=1.0, horizon=12*3600, use_pets=False):
    t=0; speed=0; w=0; boot=0; reb=0; reached=0; marks={}; pet=-1
    pos=spawn; claimed=set()
    while t<horizon and reached<len(req):
        m=boots[boot][0]*(1+reb)*mult_pass*((1+pets[pet][0]) if pet>=0 else 1)
        # next target
        n=len(claimed)
        if n<len(req) and speed>=req[n]:
            d=pads[n]-pos; dt=max(1,d/ws(speed)); t+=dt; speed+=m*dt; pos=pads[n]
            claimed.add(n); w+=wins[n]
            if n+1>reached:
                reached=n+1; marks[reached]=t
            if n==len(req)-1: claimed=set(); pos=spawn
        else:
            # blocked: farm a lap if it pays, else wait
            if n>0 and n<len(req):
                d=pads[n-1]-spawn; dt=d/ws(speed)+2; 
                # restart lap and re-run claimed pads
                t+=dt; speed+=m*dt; w+=sum(wins[:n]); pos=pads[n-1]
            else:
                t+=5; speed+=m*5
        # buy the affordable upgrade with the best multiplier gain per Wins (boots or, if enabled, the next companion)
        options=[]
        if boot+1<len(boots): options.append((boots[boot+1][0]/boots[boot][0], boots[boot+1][1], "b"))
        if use_pets and pet+1<len(pets):
            cur=(1+pets[pet][0]) if pet>=0 else 1
            options.append(((1+pets[pet+1][0])/cur, pets[pet+1][1], "p"))
        options=[o for o in options if w>=o[1]]
        if options:
            gain,cost,kind=max(options,key=lambda o: math.log(o[0])/o[1])
            w-=cost
            if kind=="b": boot+=1
            else: pet+=1
    return marks
for label,mp,up in [("free",1,False),("free + companions",1,True),("2x pass",2,False),("2x pass + companions",2,True)]:
    mk=sim(mp,use_pets=up); print(label, {k:f"{v/60:.1f}m" for k,v in mk.items()})
print("gate Z:",[round(g) for g in gates])
