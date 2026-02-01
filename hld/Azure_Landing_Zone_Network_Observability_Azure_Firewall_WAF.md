---
title: "Azure Landing Zone Network Observability Guide: Azure Firewall + App Gateway WAF (UK South + UK Central)"
date: "2026-02-01"
category: "Azure Landing Zone"
tags:
  - Azure Firewall
  - Application Gateway WAF
  - Network Watcher
  - NSG Flow Logs
  - Traffic Analytics
  - Connection Monitor
  - Hub-Spoke
  - Site-to-Site VPN
---

## Why this guide exists

Most cloud incidents are not “Azure went down.”  
They are misconfigurations, routing drift, DNS mistakes, or security controls that silently stopped being enforced.

In a hub-spoke landing zone with hybrid connectivity, those issues become expensive fast:
- Outages take longer to isolate
- Security exposure happens through bypass paths
- Audits ask for evidence you cannot produce quickly

This guide shows a Microsoft-native approach that is simpler to operate and easier to defend:
- **Azure Firewall Premium** for internal segmentation and internet egress
- **Azure Application Gateway (WAF v2)** for inbound web protection
- **NSG Flow Logs, Traffic Analytics, and Connection Monitor** for evidence, insight, and assurance

Target pattern:
- **UK South (Primary)**
- **UK Central (DR)**
- **Site-to-Site VPN**

---

## Executive briefing (CIO / CISO / CFO)

### The situation
Cloud reliability failures are now mostly caused by configuration drift, inconsistent security controls, and lack of visibility across network paths.

### The decision
Approve a Microsoft-native landing zone baseline that consolidates inspection, standardizes inbound protection, and continuously validates critical paths.

### Why the cost is justified
This is not extra networking. It is risk control.
One serious outage or security incident can exceed the annual cost of these controls.

---

## Architecture overview (plain English)

### Inbound traffic
Internet → Application Gateway WAF → internal backends

### East–west traffic
Spoke → Azure Firewall → Spoke

### Outbound traffic
Spoke → Azure Firewall → Internet

### Hybrid traffic
On‑prem → VPN Gateway → Azure Firewall → spokes

---

## Observability tools (what they do and don’t)

| Tool | What it does | What it does NOT do |
|----|----|----|
| NSG Flow Logs | Records allow/deny flows | Real‑time alerting |
| Traffic Analytics | Shows traffic patterns and drift | IDS/IPS |
| Connection Monitor | Tests critical paths | App correctness checks |

---

## Non‑negotiable design decisions

1. Single inspection plane with Azure Firewall Premium  
2. Mandatory WAF for inbound HTTP(S)  
3. Flow Logs scoped to P0/P1 only  
4. Golden paths monitored continuously  
5. Policy‑driven enforcement  

---

## Implementation (high level)

1. Deploy Azure Firewall Premium in UK South and UK Central hubs  
2. Deploy Application Gateway WAF for internet‑facing apps  
3. Force spoke traffic through firewall using UDRs  
4. Enable NSG Flow Logs v2 and Traffic Analytics  
5. Deploy Connection Monitor golden paths  

---

## Operations model

### Change windows
- Validate golden paths before change
- Capture Traffic Analytics baseline
- Re‑validate after change

### Monthly drift review
- Direct internet egress
- New east‑west flows
- Risky ports
- Cross‑region anomalies

---

## Cost model (defensible)

Cost drivers:
- Azure Firewall Premium (hourly + data processed)
- App Gateway WAF (hourly + capacity)
- Log Analytics ingestion and retention
- Flow log volume
- Connection Monitor tests

Spend control:
- Scope first
- Tune retention
- Right‑size firewall and WAF
- Adjust probe frequency

Pricing references:
- https://azure.microsoft.com/pricing/details/vpn-gateway/
- https://azure.microsoft.com/pricing/details/network-watcher/
- https://azure.microsoft.com/pricing/details/monitor/
- https://azure.microsoft.com/pricing/calculator/

---

## RACI (keep it simple)

| Area | Platform | Security | App |
|---|---|---|---|
| Firewall + routing | A/R | C | C |
| WAF policy | R | A/C | C |
| Flow logs | A/R | C | C |
| Drift reviews | R | A/C | C |
| Spoke NSGs | C | C | A/R |

---

## Truthful limitations

- Monitoring does not prevent incidents by itself  
- Firewall is not a replacement for secure application design  
- TLS inspection adds latency and overhead  
- Without change discipline, drift will return  

---

## Final recommendation

Approve this baseline if you want fewer outages, faster recovery, consistent security controls, and audit‑ready evidence.

This is not about networking.  
It is about **operational resilience**.
