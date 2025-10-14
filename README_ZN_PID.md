# Método de Ziegler–Nichols (Malha Aberta) — Guia Rápido

Este README transcreve e **detalha** as anotações da folha enviada sobre a sintonia de controladores **P / PI / PID** pelo método de **Ziegler–Nichols (ZN) baseado na reação ao degrau** (malha aberta, ~1942/1943).

> Ideia central: aplicar um **degrau** na entrada do processo, medir a resposta em “S” e aproximar o processo por um modelo de **1ª ordem com atraso (FOPDT)**  
> \[ **G(s) = K \, e^{-L s} / (T s + 1)** \]  
> onde **K** é o ganho do processo, **L** o atraso morto (tempo até a saída começar a reagir) e **T** a constante de tempo.

---

## 1) Como obter **K**, **L** e **T** a partir da curva ao degrau

1. **Aplique um degrau unitário** na entrada \(u\) (ou um degrau conhecido \(\Delta u\)).
2. **Meça a variação de saída** \(\Delta y\). O ganho do processo é  
   \[ **K = \Delta y / \Delta u**. \]
3. Trace a **reta tangente** no ponto de **maior inclinação** da curva de saída.
4. **Atraso morto \(L\)**: distância, no eixo do tempo, desde o instante do degrau até a **interseção** da tangente com o valor inicial (quando a resposta “sai do zero”).  
5. **Constante de tempo \(T\)**: distância, no eixo do tempo, entre aquela mesma interseção inicial e a **interseção** da tangente com o **valor final** da resposta.

No esboço da folha: o trecho anotado como “tempo morto” corresponde a **\(L\)**; o trecho associado ao “tempo de acomodação” é usado para estimar **\(T\)** via a construção da tangente.

> Dica: se o ponto de operação variar, repita o ensaio em **vários pontos** e use a **média** de \(K\), \(L\), \(T\).

---

## 2) Fórmulas de Ziegler–Nichols (Reação ao Degrau)

Com \(K\), \(L\) e \(T\) medidos, os parâmetros recomendados por ZN são:

| Controlador | \(K_c\) (ganho proporcional)     | \(T_i\) (tempo integral) | \(T_d\) (tempo derivativo) |
|-------------|----------------------------------|---------------------------|----------------------------|
| **P**       | \( \displaystyle \frac{T}{K\,L} \)     | —                         | —                          |
| **PI**      | \( \displaystyle 0{,}9\,\frac{T}{K\,L} \) | \( 3\,L \)                | —                          |
| **PID**     | \( \displaystyle 1{,}2\,\frac{T}{K\,L} \) | \( 2\,L \)                | \( 0{,}5\,L \)             |

Se sua implementação usa \((K_p, K_i, K_d)\) em vez de \((K_c, T_i, T_d)\), converta por:
- \( **K_p = K_c** \)
- \( **K_i = K_c / T_i** \)  \([s^{-1}]\)
- \( **K_d = K_c \, T_d** \) \([s]\)

> Observação: as fórmulas acima são o “ZN clássico” e costumam resultar em uma resposta **rápida com overshoot** (20–30%). Use a seção “Refinamentos” abaixo para suavizar.

---

## 3) Exemplo numérico curto

- Degrau aplicado: \(\Delta u = 0{,}10\) (10%)
- Variação de saída: \(\Delta y = 5{,}0\) unidades → \(K = \Delta y/\Delta u = 50\)
- Medidas pela tangente: \(L = 2\,s\), \(T = 10\,s\)

**PID (ZN):**
- \(K_c = 1{,}2\,\dfrac{T}{K\,L} = 1{,}2\,\dfrac{10}{50 \cdot 2} = 0{,}12\)
- \(T_i = 2L = 4\,s\) → \(K_i = K_c/T_i = 0{,}12/4 = 0{,}03\,s^{-1}\)
- \(T_d = 0{,}5L = 1\,s\) → \(K_d = K_c \cdot T_d = 0{,}12 \cdot 1 = 0{,}12\)

---

## 4) Validade e limitações (anotações da folha + boas práticas)

- A heurística funciona melhor quando a razão \(L/T\) não é muito grande.  
  A sua anotação cita **“só funciona se \(0{,}2 < L/T < 0{,}4\)”**. Na prática, a faixa de uso pode ser **mais ampla**, mas quanto **maior** \(L/T\), **pior** tende a ser o desempenho do ZN puro (over/oscilações).  
- **Processos integradores** ou com **grande atraso morto** pedem métodos mais suaves (Tyreus–Luyben, IMC, Åström–Hägglund) ou ajuste fino manual.
- **Faça ensaios em mais de um ponto** de operação e use a **média** (anotação da folha).

---

## 5) Refinamentos práticos

- Se houver **overshoot/oscilações** excessivas:
  - reduza \(K_c\) em **10–30%**,
  - aumente \(T_i\) (menos ação integral),
  - reduza \(T_d\) (menos derivada).
- Use **derivada filtrada** para reduzir ruído:  
  \(D(s) = K_c\,T_d \cdot \dfrac{N s}{1 + N s}\), com \(N \approx 10\)–20.
- **Antiwindup** na integral para evitar saturação do atuador.
- Em implementação **discreta**, confirme a convenção da sua biblioteca: algumas usam \((K_p, K_i, K_d)\) diretos; outras pedem \((K_p, T_i, T_d)\) e ajustam pelo tempo de amostragem.

---

## 6) Método alternativo (ZN em malha fechada, “ganho último”)

1. Zere I e D (modo P).
2. Em malha fechada, aumente \(K_p\) até obter **oscilações sustentadas**.  
   Esse ganho é \(K_u\) (ganho último); o período da oscilação é \(P_u\).
3. Parâmetros ZN:

| Controlador | \(K_p\)        | \(T_i\)     | \(T_d\)     |
|-------------|-----------------|-------------|-------------|
| **P**       | \(0{,}50\,K_u\) | —           | —           |
| **PI**      | \(0{,}45\,K_u\) | \(P_u/1{,}2\) | —         |
| **PID**     | \(0{,}60\,K_u\) | \(0{,}50\,P_u\) | \(0{,}125\,P_u\) |

---

## 7) Modelo gráfico citado na folha

- **Planta aproximada:** \( G(s) = K\, e^{-L s} / (T s + 1) \)
- **\(\Delta y\)**: variação de saída resultante do degrau \(\Delta u\).
- **Atraso morto \(L\)**: trecho inicial sem resposta (“tempo morto”).
- **Constante de tempo \(T\)**: distância entre as interseções da tangente com os níveis inicial e final.

> A figura desenhada na folha mostra a construção geométrica clássica para obter \(L\) e \(T\) via tangente à curva de reação.

---

## 8) Checklist rápido para o seu ensaio

- [ ] Coloque a malha **aberta** (sem controlador ou com controlador em “manual”).  
- [ ] Aplique um **degrau conhecido** \(\Delta u\).  
- [ ] Registre a resposta \(y(t)\) e **trace a tangente** no ponto de maior inclinação.  
- [ ] Meça \(K\), \(L\), \(T\) conforme descrito.  
- [ ] Calcule \(K_c, T_i, T_d\) pela tabela ZN.  
- [ ] **Refine** (reduza \(K_c\), ajuste \(T_i\), \(T_d\)) se houver overshoot ou ruído.

---

**Observação final:** Ziegler–Nichols é um **ponto de partida**. Use os refinamentos acima para chegar ao compromisso desejado entre rapidez, overshoot e robustez.
