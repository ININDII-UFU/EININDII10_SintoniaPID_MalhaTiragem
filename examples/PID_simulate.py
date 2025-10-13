import numpy as np
import matplotlib.pyplot as plt

# ==============================================================
# ==== Process ====
# ==============================================================

def simulate_process_FOPDT(u, dt, K, T, L):
    """
    Simulates a FOPDT process: G(s) = K * exp(-Ls) / (Ts+1)
    """
    n = len(u)
    y = np.zeros(n)
    delay_steps = int(L / dt)

    for k in range(1, n):
        u_delayed = u[k - delay_steps] if k - delay_steps >= 0 else 0.0
        y[k] = y[k-1] + dt/T * (-y[k-1] + K*u_delayed)
    return y

def simulate_process_first_order(u, dt, K, T):
    """
    First-order system: G(s) = K / (Ts + 1)
    """
    n = len(u)
    y = np.zeros(n)

    for k in range(1, n):
        y[k] = y[k-1] + dt/T * (-y[k-1] + K*u[k])
    return y

def simulate_process_second_order(u, dt, K, T1, T2):
    """
    Second-order system: G(s) = K / ((T1*s+1)(T2*s+1))
    """
    n = len(u)
    y = np.zeros(n)
    dy = np.zeros(n)  # derivada aproximada

    for k in range(1, n):
        dy[k] = dy[k-1] + dt*((- (T1+T2)*dy[k-1] - y[k-1] + K*u[k])/(T1*T2))
        y[k] = y[k-1] + dt*dy[k]
    return y

def simulate_process_integrator(u, dt, K):
    """
    Pure integrator: G(s) = K/s
    """
    n = len(u)
    y = np.zeros(n)

    for k in range(1, n):
        y[k] = y[k-1] + dt*K*u[k]
    return y

def simulate_process_integrator_delay(u, dt, K, L):
    """
    Pure integrator with delay: G(s) = K * exp(-Ls) / s
    """
    n = len(u)
    y = np.zeros(n)
    delay_steps = int(L / dt)

    for k in range(1, n):
        u_delayed = u[k - delay_steps] if k - delay_steps >= 0 else 0.0
        y[k] = y[k-1] + dt*K*u_delayed
    return y

def simulate_process_second_order_standard(u, dt, K, wn, zeta):
    """
    Standard 2nd order system:
    G(s) = (K*wn^2) / (s^2 + 2*zeta*wn*s + wn^2)
    """
    n = len(u)
    y = np.zeros(n)
    dy = np.zeros(n)

    for k in range(1, n):
        ddy = -2*zeta*wn*dy[k-1] - wn**2*y[k-1] + K*wn**2*u[k]
        dy[k] = dy[k-1] + dt*ddy
        y[k] = y[k-1] + dt*dy[k]
    return y

# ==============================================================
# ==== PID controllers ====
# ==============================================================

def simulate_pid(Kp, Ki, Kd, process_func, process_params, dt, sim_time, 
                 SP=1.0, saturation=[float('-inf'), float('inf')], 
                 D_on="y", D_filter=float('inf'), anti_windup=0):
    """
    Generic PID simulator with any process model.
    
    process_func: function that simulates the process (e.g., simulate_process_FOPDT)
    process_params: dict with parameters required by process_func
                    (ex: {"K":1, "T":5, "L":2} for FOPDT)
    """   
    n_steps = int(sim_time/dt)
    t = np.linspace(0, sim_time, n_steps)

    u = np.zeros(n_steps)
    y = np.zeros(n_steps)
    e = np.zeros(n_steps)
    sp = np.ones(n_steps) * SP

    I = 0.0
    D = 0.0
    prev_y = 0.0
    
    # D_filter
    Td = Kd/Kp if Kp != 0 else 0.0
    alpha = Td / (Td + D_filter*dt) if Td > 0 else 0.0  # D_filter: inf => no filtering ; 0 => strong filtering
    #print(f"alpha (D_filter): {alpha}")
    
    for k in range(1, n_steps):
        e[k] = sp[k] - y[k-1]
        P = Kp * e[k]
        I += Ki * e[k] * dt
        
        #D = Kd * (e[k] - e[k-1]) / dt      # D basic
        #D = Kd * (e[k] - e[k-1]) / dt if (D_on=="e") else  -Kd * (y[k-1] - prev_y) / dt     # D on "error" or "y"
        D = alpha*D + (1-alpha)*Kd * (e[k] - e[k-1]) / dt if (D_on=="e") else  alpha*D + (1-alpha)*(-Kd) * (y[k-1] - prev_y) / dt     # D on "error" or "y", with D_filter
        prev_y = y[k-1]
        
        #u[k] = P + I + D
        u_unsat = P + I + D
        u[k] = min( max( u_unsat , saturation[0]), saturation[1]) #saturation
        
        # Anti-windup (back-calculation correction on integrator)
        I += anti_windup * (u[k] - u_unsat)
        
        # Simulate process
        y[:k+1] = process_func(u[:k+1], dt=dt, **process_params)
        
    return t, sp, y, u


# ==============================================================
# === Examples =============================================
# ==============================================================

def demo_PID_parameters():
    # Process FOPDT parameters
    K, T, L = 2.0, 5.0, 1.0
    dt = 0.05
    sim_time = 20
    
    # Simulation config
    n_steps = int(sim_time / dt)

    # PID gains
    Kp, Ki, Kd = 3.0, 1.5, 1.25

    # Run simulations
    u_open = np.ones(n_steps)  # unit step
    y_open_loop = simulate_process_FOPDT(u_open, dt, K, T, L)
    t1, sp1, y1, u1 = simulate_pid(
        Kp, Ki, Kd,
        process_func=simulate_process_FOPDT,
        process_params={"K":K, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e"
    )
    
    t2, sp2, y2, u2 = simulate_pid(
        Kp, Ki, Kd,
        process_func=simulate_process_FOPDT,
        process_params={"K":K, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e", D_filter=10
    )
    t3, sp3, y3, u3 = simulate_pid(
        Kp, Ki, Kd,
        process_func=simulate_process_FOPDT,
        process_params={"K":K, "T":T, "L":L},
        dt=dt, sim_time=sim_time
    )
    t4, sp4, y4, u4 = simulate_pid(
        Kp, Ki, Kd,
        process_func=simulate_process_FOPDT,
        process_params={"K":K, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e", saturation= [0, 2.5]
    )
    t5, sp5, y5, u5 = simulate_pid(
        Kp, Ki, Kd,
        process_func=simulate_process_FOPDT,
        process_params={"K":K, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e", saturation= [0, 2.5], anti_windup= 1/Kp
    )


    # Plot results
    plt.figure(figsize=(14,8))

    plt.subplot(2,1,1)
    plt.plot(t1, sp1, 'k--', label="Setpoint")
    plt.plot(t1, y_open_loop, 'b', label="PV - Step Response")
    plt.plot(t1, y1, 'g', label="PV - Derivative on Error")
    plt.plot(t2, y2, 'c', label="PV - Derivative on Error, D_filter")
    plt.plot(t3, y3, 'r', label="PV - Derivative on Output")
    plt.plot(t4, y4, 'm', label="PV - Derivative on Error, Saturation")
    plt.plot(t5, y5, 'y', label="PV - Derivative on Error, Saturation, Anti-windup")
    plt.title("Process FOPDT - different implementations for PID")
    plt.xlabel("Time [s]")
    plt.ylabel("PV")
    plt.legend(loc="upper right")
    plt.grid(True)

    plt.subplot(2,1,2)
    plt.plot(t1, u1, 'g', label="MV - Derivative on Error")
    plt.plot(t2, u2, 'c', label="MV - Derivative on Error, D_filter")
    plt.plot(t3, u3, 'r', label="MV - Derivative on Output")
    plt.plot(t4, u4, 'm', label="MV - Derivative on Error, Saturation")
    plt.plot(t5, u5, 'y', label="MV - Derivative on Error, Saturation, Anti-windup")
    plt.title("Manipulated Variable (MV)")
    plt.xlabel("Time [s]")
    plt.ylabel("MV")
    plt.legend(loc="upper right")
    plt.grid(True)

    plt.tight_layout()
    plt.show()

def demo_processes():
    """Compara processos sem controle (resposta a degrau)"""
    dt, sim_time = 0.05, 30
    n = int(sim_time/dt)
    u = np.ones(n)  # entrada degrau unitário

    cases = {
        "1ª ordem (K=1,T=5)": (simulate_process_first_order, {"K":1,"T":5}),
        "FOPDT (K=1,T=5,L=3)": (simulate_process_FOPDT, {"K":1,"T":5,"L":3}),
        "2ª ordem (K=1,T1=5,T2=4)": (simulate_process_second_order, {"K":1,"T1":5,"T2":4}),
        #"Integrador (K=0.5)": (simulate_process_integrator, {"K":0.5}),
        "Oscilador (K=1, wn=1,zeta=0.2)": (simulate_process_second_order_standard, {"K":1,"wn":1,"zeta":0.2}),
    }

    plt.figure(figsize=(10,6))
    for label,(func,params) in cases.items():
        y = func(u, dt, **params)
        plt.plot(np.arange(n)*dt, y, label=label)

    plt.plot(np.arange(n)*dt, u, 'k--', label="Entrada (degrau)")
    plt.title("Comparação de processos dinâmicos (resposta a degrau)")
    plt.xlabel("Tempo")
    plt.ylabel("Saída")
    plt.legend()
    plt.grid()
    plt.show()

def demo_pid_on_fopdt():
    """Testa PID em FOPDT variando atraso"""
    dt, sim_time = 0.05, 50

    cases = {
        "Atraso pequeno (L=1)": {"K":1,"T":5,"L":1},
        "Atraso grande (L=5)": {"K":1,"T":5,"L":5},
    }

    plt.figure(figsize=(10,6))
    for label,params in cases.items():
        t, sp, y, u = simulate_pid(1.5, 0.4, 0.2,
                                   simulate_process_FOPDT, params,
                                   dt, sim_time)
        plt.plot(t, y, label=label)
    plt.plot(t, sp, 'k--', label="SP")
    plt.title("PID em FOPDT com diferentes atrasos")
    plt.xlabel("Tempo")
    plt.ylabel("Saída")
    plt.legend()
    plt.grid()
    plt.show()

def demo_pid_on_second_order():
    
    """Compara PID em sistemas 2ª ordem com diferentes amortecimentos"""
    dt, sim_time = 0.02, 20

    cases = {
        "Subamortecido (ζ=0.2)": {"K":1,"wn":2,"zeta":0.2},
        "Amortecimento crítico (ζ=1)": {"K":1,"wn":2,"zeta":1.0},
        "Superamortecido (ζ=2)": {"K":1,"wn":2,"zeta":2.0},
    }

    plt.figure(figsize=(10,6))
    for label,params in cases.items():
        t, sp, y, u = simulate_pid(2.0, 0.5, 0.1,
                                   simulate_process_second_order_standard, params,
                                   dt, sim_time)
        plt.plot(t, y, label=label)
    plt.plot(t, sp, 'k--', label="SP")
    plt.title("PID em sistemas de 2ª ordem com diferentes amortecimentos")
    plt.xlabel("Tempo")
    plt.ylabel("Saída")
    plt.legend()
    plt.grid()
    plt.show()

def fopdt_identification(process_func, params, dt=0.05, sim_time=30, step=1.0):
    """
    Approximate a process as FOPDT using the tangent method.
    
    Parameters:
    - process_func : function that simulates the process
    - params       : dict with process parameters
    - dt           : simulation time step
    - sim_time     : total simulation time
    - step         : input step magnitude
    """
    n = int(sim_time/dt)
    t = np.arange(n)*dt
    u = np.ones(n) * step
    y = process_func(u, dt, **params)

    # Process gain (steady state change / input change)
    K = (y[-1] - y[0]) / step

    # Numerical derivative
    dy = np.gradient(y, dt)

    # Inflexion point (max derivative)
    k_infl = np.argmax(dy)
    t_infl, y_infl, slope = t[k_infl], y[k_infl], dy[k_infl]

    # Tangent line
    tangent = y_infl + slope*(t - t_infl)

    # Dead time L: when tangent crosses y=0
    L = t_infl - y_infl/slope

    # Tau T: time between L and tangent crossing steady state
    T=[0,0]
        #Option 1: Inflexion
    T[0] = ( (K*step - y_infl)/slope + t_infl ) - L
    
        #Option 2: 63.2% of Y
    y_target = K * step * (1 - np.exp(-1))  # 63.2% of Y
    idx_tau = np.where(y >= y_target)[0][0]  # y >= alvo
    T[1] = t[idx_tau] - L


    # === Plot ===
    #plt.figure(figsize=(8,5))
    plt.plot(t, y, 'b', label="Process output y(t)")
    plt.plot(t, tangent, 'r--', label="Tangent at inflection")
    plt.axhline(K*step, color="k", linestyle="--", label="Asymptote Ks")
    plt.axvline(L, color="k", linestyle="--", label=f"L = {L:.2f}")
    plt.axvline(L+T[0], color="k", linestyle="--", label=f"L+T = {L+T[0]:.2f}")
    
    plt.title("FOPDT Approximation (Tangent Method)")
    plt.xlabel("Time [s]")
    plt.ylabel("y(t)")
    plt.ylim(bottom=min(y),top=max(y)*1.2)
    plt.legend()
    plt.grid(True)
    plt.show()

    return {"K": K, "L": L, "T": T}

def demo_fopdt_identification_second_order():
    # Aproximar o processo de 2ª ordem como FOPDT
    second_order_params = {"K":1, "T1":5, "T2":4}
    fopdt_params = fopdt_identification(simulate_process_second_order, second_order_params)
    print(fopdt_params)
    
    """Compara processos"""
    dt, sim_time = 0.05, 30
    n = int(sim_time/dt)
    u = np.ones(n)  # entrada degrau unitário

    cases = {
        f"FOPDT_identification_inflexion (K={fopdt_params["K"]},T={fopdt_params["T"][0]},L={fopdt_params["L"]})": (simulate_process_FOPDT, {"K":fopdt_params["K"], "L":fopdt_params["L"],"T":fopdt_params["T"][0]}),
        f"FOPDT_identification_63% (K={fopdt_params["K"]},T={fopdt_params["T"][1]},L={fopdt_params["L"]})": (simulate_process_FOPDT, {"K":fopdt_params["K"], "L":fopdt_params["L"],"T":fopdt_params["T"][1]}),
        f"2ª ordem (K={second_order_params["K"]},T1={second_order_params["T1"]},T2={second_order_params["T2"]})": (simulate_process_second_order, second_order_params),
    }

    plt.figure(figsize=(10,6))
    for label,(func,params) in cases.items():
        y = func(u, dt, **params)
        plt.plot(np.arange(n)*dt, y, label=label)

    plt.plot(np.arange(n)*dt, u, 'k--', label="Entrada (degrau)")
    plt.title("Comparação de processos dinâmicos (resposta a degrau)")
    plt.xlabel("Tempo")
    plt.ylabel("Saída")
    plt.legend(loc="upper center", framealpha=0.7)
    plt.grid()
    plt.show()

def demo_fopdt_identification_second_order_standard():
    # Aproximar o processo de 2ª ordem como FOPDT
    second_order_params = {"K":1,"wn":1,"zeta":0.2}
    fopdt_params = fopdt_identification(simulate_process_second_order_standard, second_order_params)
    print(fopdt_params)
    
    """Compara processos"""
    dt, sim_time = 0.05, 30
    n = int(sim_time/dt)
    u = np.ones(n)  # entrada degrau unitário

    cases = {
        f"FOPDT_identification_inflexion (K={fopdt_params["K"]},T={fopdt_params["T"][0]},L={fopdt_params["L"]})": (simulate_process_FOPDT, {"K":fopdt_params["K"], "L":fopdt_params["L"],"T":fopdt_params["T"][0]}),
        f"FOPDT_identification_63% (K={fopdt_params["K"]},T={fopdt_params["T"][1]},L={fopdt_params["L"]})": (simulate_process_FOPDT, {"K":fopdt_params["K"], "L":fopdt_params["L"],"T":fopdt_params["T"][1]}),
        f"2ª ordem (K={second_order_params["K"]},wn={second_order_params["wn"]},zeta={second_order_params["zeta"]})": (simulate_process_second_order_standard, second_order_params),
    }

    plt.figure(figsize=(10,6))
    for label,(func,params) in cases.items():
        y = func(u, dt, **params)
        plt.plot(np.arange(n)*dt, y, label=label)

    plt.plot(np.arange(n)*dt, u, 'k--', label="Entrada (degrau)")
    plt.title("Comparação de processos dinâmicos (resposta a degrau)")
    plt.xlabel("Tempo")
    plt.ylabel("Saída")
    plt.legend(loc="upper center", framealpha=0.7)
    plt.grid()
    plt.show()


# ==============================================================
# === MAIN =====================================================
# ==============================================================

if __name__ == "__main__":
    demo_PID_parameters()
    #demo_processes()
    #demo_pid_on_fopdt()
    #demo_pid_on_second_order()
    #demo_fopdt_identification_second_order()
    #demo_fopdt_identification_second_order_standard()
