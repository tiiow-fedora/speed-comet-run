"""Rough economy sim: a greedy player runs, farms laps when blocked, buys the best upgrade per Wins and (optionally) rebirths.

Every number comes from src/shared/Config.luau (parsed below), so the sim cannot drift from the game again.
Usage:  python3 tools/balance_sim.py            (summary table)
        python3 tools/balance_sim.py --detail   (every stage time per scenario)
It models: stage geometry (mirrors MapBuilder), boots, companions, rebirth (cost, head start, star bonus, milestone purse),
the first-clear bonus and the 2x Speed pass. It does not model trophies, gifts, quests, shards, events or friends, so real
players are somewhat faster than this; treat it as a pacing sanity check, not a forecast.
"""
import math
import re
import sys
from pathlib import Path

CFG = (Path(__file__).resolve().parent.parent / "src/shared/Config.luau").read_text()


def block(name):
    m = re.search(r"Config\.%s = \{(.*?)\n\} :: " % name, CFG, re.S)
    return m.group(1)


def nums(text, key):
    return [float(x) for x in re.findall(r"\b%s = ([0-9.]+)" % key, text)]


stages_txt = block("Stages")
REQ = nums(stages_txt, "Req")
WINS = nums(stages_txt, "Wins")
boots_txt = block("Boots")
BOOTS = list(zip(nums(boots_txt, "Mult"), nums(boots_txt, "Cost")))
pets_txt = block("Companions")
PETS = list(zip(nums(pets_txt, "Bonus"), nums(pets_txt, "Cost")))
ms_txt = block("RebirthMilestones")
MILESTONES = {int(a): m for a, m in zip(nums(ms_txt, "At"), nums(ms_txt, "WinsMult"))}


def const(name, default=None):
    m = re.search(r"Config\.%s = ([0-9.]+)" % name, CFG)
    return float(m.group(1)) if m else default


GRAV = const("Gravity")
JUMP = const("JumpHeight")
HEADSTART = const("HeadStartFrac")
STAR_EVERY = int(const("StarEvery"))
STAR_BONUS = const("StarBonus")
QUEST_MIN = const("QuestMinBase")
PREMIUM = 1.0  # free player


def rebirth_cost(r):  # Config.RebirthCost
    m = re.search(r"function Config\.RebirthCost.*?return ([0-9.]+) \* \(rebirths \+ 1\)", CFG, re.S)
    return float(m.group(1)) * (r + 1)


def ws(s):  # Config.WalkSpeedFor
    return min(140, 16 + 12 * math.log(1 + max(s, 0) / 5))


T = 2 * math.sqrt(2 * GRAV * JUMP) / GRAV
# stage geometry (mirror MapBuilder.build)
z = 40
PADS, GATES = [], []
for i in range(1, len(REQ) + 1):
    prev = REQ[i - 2] if i > 1 else 0
    gap = 6 if i == 1 else min(45, max(8, ws(prev) * T * 0.5))
    z += 60 + 8 * i
    isl = 22 + i
    z += 2 * (gap + isl) + gap
    z += 70 + 10 * i
    GATES.append(z - 6)
    PADS.append(z + 25)
    z += 70 if i == len(REQ) else 50
SPAWN = -20


def sim(speed_pass=1.0, use_pets=False, rebirth=None, horizon=24 * 3600):
    """rebirth: None (never) or a minimum multiplier gain (e.g. 1.2 = rebirth when it raises gain by 20%+ and the player is blocked)."""
    t = 0.0
    speed = 0.0
    wins = 0.0
    boot = 0
    reb = 0
    pet = -1
    best = 0
    marks = {}
    rebirth_times = []
    pos = SPAWN
    claimed = set()
    n_stages = len(REQ)

    def star(r):
        return 1 + STAR_BONUS * (r // STAR_EVERY)

    def gain():
        return BOOTS[boot][0] * (1 + reb) * star(reb) * speed_pass * ((1 + PETS[pet][0]) if pet >= 0 else 1)

    while t < horizon and best < n_stages:
        m = gain()
        n = len(claimed)
        if n < n_stages and speed >= REQ[n]:
            d = PADS[n] - pos
            dt = max(1, d / ws(speed))
            t += dt
            speed += m * dt
            pos = PADS[n]
            claimed.add(n)
            first = n + 1 > best
            wins += WINS[n] * (2 if first else 1)
            if first:
                best = n + 1
                marks[best] = t
            if n == n_stages - 1:
                claimed = set()
                pos = SPAWN
        else:
            if n > 0 and n < n_stages:
                d = PADS[n - 1] - SPAWN
                dt = d / ws(speed) + 2
                t += dt
                speed += m * dt
                wins += sum(WINS[:n])
                pos = PADS[n - 1]
            else:
                t += 5
                speed += m * 5
        # rebirth when blocked, affordable and worth it
        if rebirth and n < n_stages and speed < REQ[n] and speed >= rebirth_cost(reb):
            new = BOOTS[boot][0] * (2 + reb) * star(reb + 1) * speed_pass * ((1 + PETS[pet][0]) if pet >= 0 else 1)
            if new / m >= rebirth:
                reb += 1
                rebirth_times.append(t)
                speed = math.floor(rebirth_cost(reb - 1) * HEADSTART)
                wins = 0
                if reb in MILESTONES:
                    wins += MILESTONES[reb] * max(QUEST_MIN, WINS[max(best, 1) - 1])
                claimed = set()
                pos = SPAWN
                t += 3
        options = []
        if boot + 1 < len(BOOTS):
            options.append((BOOTS[boot + 1][0] / BOOTS[boot][0], BOOTS[boot + 1][1], "b"))
        if use_pets and pet + 1 < len(PETS):
            cur = (1 + PETS[pet][0]) if pet >= 0 else 1
            options.append(((1 + PETS[pet + 1][0]) / cur, PETS[pet + 1][1], "p"))
        options = [o for o in options if wins >= o[1]]
        if options:
            g, cost, kind = max(options, key=lambda o: math.log(o[0]) / max(o[1], 1))
            wins -= cost
            if kind == "b":
                boot += 1
            else:
                pet += 1
    return marks, rebirth_times, t


def fmt(marks, which):
    return " ".join(("s%d=%.0fm" % (k, marks[k] / 60)) if k in marks else ("s%d=--" % k) for k in which)


if __name__ == "__main__":
    detail = "--detail" in sys.argv
    scenarios = [
        ("free, no rebirth", 1, False, None),
        ("free + companions", 1, True, None),
        ("free + companions + rebirth(1.15)", 1, True, 1.15),
        ("free + companions + rebirth(1.5)", 1, True, 1.5),
        ("2x pass + companions + rebirth(1.15)", 2, True, 1.15),
    ]
    which = [5, 10, 15, 16, 20]
    print("stages:", len(REQ), "| boots:", len(BOOTS), "| companions:", len(PETS), "| lap length:", round(z))
    for label, sp, up, rb in scenarios:
        marks, rbs, t_end = sim(sp, up, rb)
        extra = " rebirths=%d" % len(rbs)
        print("%-40s %s%s" % (label, fmt(marks, which), extra))
        if detail:
            print("   ", {k: round(v / 60, 1) for k, v in marks.items()})
    print("gate Z:", [round(g) for g in GATES])
