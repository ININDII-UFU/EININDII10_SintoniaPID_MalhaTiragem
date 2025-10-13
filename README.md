# 🧠 PID_ZN_FOPDT — Simulação e Sintonia Ziegler-Nichols (FOPDT)

Este notebook apresenta uma implementação **didática e interativa** para estudo de **Controle PID** aplicado a **processos FOPDT** (First Order Plus Dead Time).  
O objetivo é compreender o efeito dos parâmetros de sintonia (Kp, Ki, Kd) com base no **método clássico de Ziegler–Nichols** e visualizar respostas temporais de sistemas industriais simples.

---

## 🚀 Execute no Google Colab

Clique no botão abaixo para abrir e rodar o notebook **diretamente no navegador**:

[![Abrir no Colab](https://colab.research.google.com/assets/colab-badge.svg)](
https://colab.research.google.com/github/ININDII-UFU/EININDII04_SintoniaPID/blob/main/PID_ZN_FOPDT.ipynb)

---

## 📚 Conteúdo do Notebook

### Seções principais
1. **Introdução ao modelo FOPDT**
   - G(s) = K * exp(-L s) / (T s + 1)
   - Conceitos de ganho (K), constante de tempo (T) e atraso (L)

2. **Simulação no tempo discreto**
   - Integração numérica via método de Euler
   - Implementação em Python com NumPy

3. **Controlador PID**
   - Estrutura: u(t) = Kp e(t) + Ki ∫ e(t)dt + Kd de(t)/dt
   - Variações: derivada no erro ou na saída, anti-windup, saturação

4. **Método de sintonia Ziegler–Nichols**
   - Determinação de Kcr e Pcr
   - Cálculo dos parâmetros Kp, Ti, Td
   - Tabelas clássicas de sintonia

5. **Experimentos interativos**
   - Gráficos de resposta ao degrau
   - Comparação de diferentes ajustes de PID
   - Efeito de atraso e de filtro derivativo

---

## ⚙️ Requisitos

```bash
pip install numpy matplotlib
```

O notebook foi testado em:
- Python 3.9+
- NumPy ≥ 1.22
- Matplotlib ≥ 3.5
- Google Colab (ambiente padrão)

---

## 🧩 Estrutura interna

| Função / Bloco | Descrição |
|----------------|------------|
| simulate_process_FOPDT() | Simula processo de 1ª ordem + atraso |
| simulate_pid() | Simulador PID genérico (com saturação e anti-windup) |
| ziegler_nichols_tuning() | Calcula ganhos PID a partir de testes de oscilação crítica |
| plot_responses() | Gera gráficos de PV e MV |
| demo_experiments() | Roda exemplos prontos e compara estratégias de sintonia |

---

## 💡 Conceitos-chave

- **FOPDT:** aproximação comum de processos industriais simples.  
- **Ziegler–Nichols:** método experimental clássico para sintonizar P, PI e PID.  
- **Anti-windup:** evita saturação do integrador.  
- **Filtro D:** suaviza derivada frente a ruído de medição.

---

## 📈 Exemplo rápido (execução local)

```python
from PID_ZN_FOPDT import simulate_process_FOPDT, simulate_pid
import numpy as np, matplotlib.pyplot as plt

params = {"K": 2.0, "T": 5.0, "L": 1.0}
t, sp, y, u = simulate_pid(
    Kp=3.0, Ki=1.5, Kd=1.25,
    process_func=simulate_process_FOPDT,
    process_params=params,
    dt=0.05, sim_time=20
)

plt.plot(t, y, label="Saída (PV)")
plt.plot(t, sp, "k--", label="Setpoint")
plt.legend(); plt.grid(True); plt.show()
```

---

## 🧠 Sugestões de Extensão

- Comparar métodos de sintonia (Z-N, Cohen–Coon, IMC)  
- Implementar ruído na medição e filtro de Kalman  
- Interface gráfica interativa (Dash/Streamlit)  
- Geração automática de relatórios de desempenho (overshoot, settling time, IAE)

---

## 📝 Licença

Distribuído sob **MIT License**.  
Livre para uso acadêmico, didático e de pesquisa, mediante citação do autor.

---

## 🙌 Créditos

Desenvolvido para fins educacionais em **Engenharia de Controle e Automação**  
por **Josué Morais & Colaboradores**  
📧 contato: josuemorais@ufu.br

---

### ⭐ Dica
Se o projeto te ajudou, dê uma estrela ⭐ no repositório para apoiar o desenvolvimento!
