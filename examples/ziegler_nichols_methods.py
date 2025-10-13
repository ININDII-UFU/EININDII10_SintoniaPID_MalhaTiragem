"""
Ziegler–Nichols PID Tuning (First Method - Process Reaction Curve)
with Simulation and Plots

This script:
1. Tunes PID gains using Ziegler–Nichols First Method.
2. Simulates a first-order plus dead-time (FOPDT) process.
3. Shows response without control (open-loop).
4. Shows closed-loop response with PID controller (no derivative filter, saturation or back-calculation anti-windup).


Author: Keslley Brito Ramos
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import lti, dlti, cont2discrete, find_peaks

import sys
import os
# Adiciona a pasta raiz ao PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from examples.PID_simulate import simulate_process_FOPDT, simulate_pid


# =====================
# PID TUNING FUNCTION
# =====================

def ziegler_nichols_first_method(K, L, T): # to process FOPDT
    """Return Z-N PID parameters."""
    results = {}
    results["PID"] = {
        "Kp": 1.2 * T / (K * L),
        "Ki": 0.6 * T / (K * L**2), # = Kp*Ti = Kp/Tn = Kp/(2L)
        "Kd": 0.5 * T / K,          # = Kp*Td = Kp*Tv = Kp*(L/2)
    }
    return results

def ziegler_nichols_second_method(Ku, Pu): # using ultimate gains
    """
    Ziegler–Nichols Second Method (Ultimate Gain Method).
    
    Parameters:
    - Ku : ultimate gain (gain at sustained oscillation)
    - Pu : ultimate period (oscillation period at Ku)

    Returns:
    - dict with PID parameters
    """
    results = {}
    results["PID"] = {
        "Kp": 0.6 * Ku,
        "Ki": 1.2 * Ku / Pu,   # equivalently Kp/Ti with Ti = Pu/2
        "Kd": 0.075 * Ku * Pu  # equivalently Kp*Td with Td = Pu/8
    }
    return results

def find_ultimate_gain(simulate_pid, process_func, process_params, dt, sim_time, Kp_range=np.linspace(1, 5, 100)): #  -> 1 : 5*Kp_process
    
    """
    Automatic search for ultimate gain Ku and ultimate period Pu,
    using simulate_pid with proportional-only control.

    Parameters:
    - simulate_pid   : function to simulate closed-loop PID
    - process_func   : process simulation function (e.g. simulate_process_FOPDT)
    - process_params : dict with process parameters
    - dt             : simulation time step
    - sim_time       : total simulation time
    - Kp_range       : range of proportional gains to test

    Returns:
    - Ku : ultimate gain (proportional gain that yields sustained oscillations)
    - Pu : ultimate period of oscillation
    """
    print("search for ultimate gain...")
    
    n_steps = int(sim_time / dt)
    t = np.linspace(0, sim_time, n_steps)

    for Kp in Kp_range:
        # Just Kp
        Kd = 0.0
        Ki = 0.0
        
        t_sim, sp, y, u = simulate_pid(
            Kp, Ki, Kd,
            process_func=process_func,
            process_params=process_params,
            dt=dt,
            sim_time=sim_time,
            D_on="e"
        )
        
        
        # Detect peaks in the output signal
        peaks, _ = find_peaks(y, distance=int(0.5/dt))
        if len(peaks) >= 6:  # need at least several oscillations
            # Estimate oscillation period from last peaks
            periods = np.diff(t[peaks][-5:])
            avg_period = np.mean(periods)

            # Check if oscillations are approximately sustained
            last_amps = y[peaks][-5:]
            print(f"Kp:{Kp}, last_amps:{last_amps}")
            if(last_amps[-2]>last_amps[-1]):
                print("Converging...")
                continue
            if(last_amps[-2]<last_amps[-1]):
                print("Diverging...")
            
            tolerance = np.std(last_amps) / np.mean(last_amps)
            print(f"tolerance:{tolerance}")
            if tolerance < 0.01:  # % tolerance
                # Plot
                plt.plot(t, y, 'b-', linewidth=2, label="FOPDT Output")
                plt.title(f"Step Response - Find ultimate gain (Kp={Kp})")
                plt.xlabel("Time [s]")
                plt.ylabel("Amplitude")
                plt.legend()
                plt.grid(True)
                plt.show()
                return Kp, avg_period
    
    print("No sustained oscillations found!")
    # Plot
    plt.plot(t, y, 'b-', linewidth=2, label="FOPDT Output")
    plt.title(f"Step Response - No sustained oscillations found! (Kp={Kp})")
    plt.xlabel("Time [s]")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid(True)
    plt.show()
    return None, None  # no sustained oscillations found

# =====================
# Tests
# =====================
def test_first_method():
    # Process parameters
    Kp_process = 2.0 #0.006605/1   # process gain (dy/du)
    L = 1 #2.101         # dead time [s]
    T = 5 #3.5        # time constant [s]
    print(f"Kp: {Kp_process}| L: {L}| T: {T}")

    # Simulation config
    dt = 0.1
    sim_time = 40.0
    n_steps = int(sim_time / dt)
    t = np.linspace(0, sim_time, n_steps)

    # Open-loop (step response)
    u_open = np.ones(n_steps)  # unit step
    y_open = simulate_process_FOPDT(u_open, dt, Kp_process, T, L)

    # Z-N tuning
    pid_params = ziegler_nichols_first_method(Kp_process, L, T)["PID"]
    print("pid_params:")
    #print(pid_params)
    #print(f"Kc (Kp): {pid_params["Kp"]}| Ti (Ki/Kp): {pid_params["Ki"]/pid_params["Kp"]}| Td (Kd/Kp): {pid_params["Kd"]/pid_params["Kp"]}| ")
    print(f"Kc (Kp): {pid_params["Kp"]}| Tn (Kp/Ki): {pid_params["Kp"]/pid_params["Ki"]}| Tv (Kd/Kp): {pid_params["Kd"]/pid_params["Kp"]}| ")
    
    t, sp, y_pid, u_pid = simulate_pid(
        pid_params["Kp"], pid_params["Ki"],pid_params["Kd"],
        process_func=simulate_process_FOPDT,
        process_params={"K":Kp_process, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e" #, saturation= [0, 100]
    )
    
    # adjustment
    pid_params_adj = pid_params.copy()
    pid_params_adj["Kp"] *= 0.5
    pid_params_adj["Ki"] *= 0.5
    pid_params_adj["Kd"] *= 0.5
    print("pid_params_teste:")
    #print(f"Kp: {pid_params_test["Kp"]}| Ki: {pid_params_test["Ki"]}| Kd: {pid_params_test["Kd"]} ")
    #print(f"Kc (Kp): {pid_params_test["Kp"]}| Ti (Ki/Kp): {pid_params_test["Ki"]/pid_params_test["Kp"]}| Td (Kd/Kp): {pid_params_test["Kd"]/pid_params_test["Kp"]}| ")
    print(f"Kc (Kp): {pid_params_adj["Kp"]}| Tn (Kp/Ki): {pid_params_adj["Kp"]/pid_params_adj["Ki"]}| Tv (Kd/Kp): {pid_params_adj["Kd"]/pid_params_adj["Kp"]}| ")

    # Closed-loop simulation with PID
    t_test, sp_test, y_pid_test, u_pid_test = simulate_pid(
        pid_params_adj["Kp"], pid_params_adj["Ki"],pid_params_adj["Kd"],
        process_func=simulate_process_FOPDT,
        process_params={"K":Kp_process, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e" #, saturation= [0, 100]
    )
    

    # =====================
    # PLOTS
    # =====================
    fig, axs = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

    # Open-loop response
    axs[0].plot(t, sp, "k--", label="SP (Setpoint)")
    axs[0].plot(t, y_open, label="PV (Open-loop)", color="blue")
    axs[0].plot(t, y_pid, label="PV (PID_Zigler_Nichols_first_method)", color="c")
    axs[0].plot(t, y_pid_test, label="PV (PID_ZN_adjuted)", color="r")
    axs[0].set_title("System Response - first_method")
    axs[0].set_ylabel("Value")
    axs[0].legend(loc="upper right")
    axs[0].grid(True)
    
    # Closed-loop with PID
    axs[1].plot(t, u_pid, label="MV_ZN (Manipulated Variable)", color="c")
    axs[1].plot(t, u_pid_test, label="MV_ZN_adj (Manipulated Variable)", color="r")
    axs[1].set_title("Closed-loop response with PID - first_method")
    axs[1].set_xlabel("Time [s]")
    axs[1].set_ylabel("Value")
    axs[1].legend(loc="upper right")
    axs[1].grid(True)

    plt.tight_layout()
    plt.show()

def test_second_method():
    
    # Process parameters
    Kp_process = 2.0 #0.006605/1   # process gain (dy/du)
    L = 1 #2           # dead time [s]
    T = 5 #3.5            # time constant [s]
    print(f"Kp: {Kp_process}| L: {L}| T: {T}")

    # Simulation config
    dt = 0.1
    sim_time = 30.0
    n_steps = int(sim_time / dt)
    t = np.linspace(0, sim_time, n_steps)

    # Open-loop (step response)
    u_open = np.ones(n_steps)  # unit step
    y_open = simulate_process_FOPDT(u_open, dt, Kp_process, T, L)

    # Z-N tuning:
    
    # find Ku e Pu
    Ku, Pu = find_ultimate_gain(
        simulate_pid,
        process_func=simulate_process_FOPDT,
        process_params={"K":Kp_process, "T":T, "L":L},
        dt=dt,
        sim_time=sim_time
    )
    print("Ku =", Ku, " Pu =", Pu)
    if(Ku==None): return  print("try others parameters.")
    pid_params = ziegler_nichols_second_method(Ku, Pu)["PID"]
    print("pid_params:")
    #print(pid_params)
    #print(f"Kc (Kp): {pid_params["Kp"]}| Ti (Ki/Kp): {pid_params["Ki"]/pid_params["Kp"]}| Td (Kd/Kp): {pid_params["Kd"]/pid_params["Kp"]}| ")
    print(f"Kc (Kp): {pid_params["Kp"]}| Tn (Kp/Ki): {pid_params["Kp"]/pid_params["Ki"]}| Tv (Kd/Kp): {pid_params["Kd"]/pid_params["Kp"]}| ")
    
    t, sp, y_pid, u_pid = simulate_pid(
        pid_params["Kp"], pid_params["Ki"],pid_params["Kd"],
        process_func=simulate_process_FOPDT,
        process_params={"K":Kp_process, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e" #, saturation= [0, 100]
    )
    
    # adjustment
    pid_params_adj = pid_params.copy()
    pid_params_adj["Kp"] *= 0.5
    pid_params_adj["Ki"] *= 0.5
    pid_params_adj["Kd"] *= 0.5
    print("pid_params_teste:")
    #print(f"Kp: {pid_params_test["Kp"]}| Ki: {pid_params_test["Ki"]}| Kd: {pid_params_test["Kd"]} ")
    #print(f"Kc (Kp): {pid_params_test["Kp"]}| Ti (Ki/Kp): {pid_params_test["Ki"]/pid_params_test["Kp"]}| Td (Kd/Kp): {pid_params_test["Kd"]/pid_params_test["Kp"]}| ")
    print(f"Kc (Kp): {pid_params_adj["Kp"]}| Tn (Kp/Ki): {pid_params_adj["Kp"]/pid_params_adj["Ki"]}| Tv (Kd/Kp): {pid_params_adj["Kd"]/pid_params_adj["Kp"]}| ")

    # Closed-loop simulation with PID
    t_test, sp_test, y_pid_test, u_pid_test = simulate_pid(
        pid_params_adj["Kp"], pid_params_adj["Ki"],pid_params_adj["Kd"],
        process_func=simulate_process_FOPDT,
        process_params={"K":Kp_process, "T":T, "L":L},
        dt=dt, sim_time=sim_time, D_on="e" #, saturation= [0, 100]
    )
    

    # =====================
    # PLOTS
    # =====================
    fig, axs = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

    # Open-loop response
    axs[0].plot(t, sp, "k--", label="SP (Setpoint)")
    axs[0].plot(t, y_open, label="PV (Open-loop)", color="blue")
    axs[0].plot(t, y_pid, label="PV (PID_Zigler_Nichols_second_method)", color="c")
    axs[0].plot(t, y_pid_test, label="PV (PID_ZN_adj)", color="r")
    axs[0].set_title("System Response - second_method")
    axs[0].set_ylabel("Value")
    axs[0].legend(loc="upper right")
    axs[0].grid(True)
    
    # Closed-loop with PID
    axs[1].plot(t, u_pid, label="MV_ZN (Manipulated Variable)", color="c")
    axs[1].plot(t, u_pid_test, label="MV_test (Manipulated Variable)", color="r")
    axs[1].set_title("Closed-loop response with PID - second_method")
    axs[1].set_xlabel("Time [s]")
    axs[1].set_ylabel("Value")
    axs[1].legend(loc="upper right")
    axs[1].grid(True)

    plt.tight_layout()
    plt.show()


# =====================
# MAIN SCRIPT
# =====================
if __name__ == "__main__":
    test_first_method()
    test_second_method()