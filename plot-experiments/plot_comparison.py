import pandas as pd
import matplotlib.pyplot as plt


def create_comparison_plots(function_id: int):

    r_conv = pd.read_csv(f"../des_comparison/r_convergence_f{function_id}_d10.csv")
    py_conv = pd.read_csv(f"../../python-evo/python_convergence_f{function_id}_d10.csv")

    r_summary = pd.read_csv(f"../des_comparison/r_summary_f{function_id}_d10.csv")
    py_summary = pd.read_csv(f"../../python-evo/python_summary_f{function_id}_d10.csv")

    min_rows_conv = min(len(r_conv), len(py_conv))
    min_cols_conv = min(len(r_conv.columns), len(py_conv.columns))

    r_conv = r_conv.iloc[:min_rows_conv, :min_cols_conv]
    py_conv = py_conv.iloc[:min_rows_conv, :min_cols_conv]

    min_rows_summary = min(len(r_summary), len(py_summary))

    r_summary = r_summary.iloc[:min_rows_summary]
    py_summary = py_summary.iloc[:min_rows_summary]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))

    # Convergence curves
    r_median = r_conv.median(axis=1).dropna()
    r_q25 = r_conv.quantile(0.25, axis=1).dropna()
    r_q75 = r_conv.quantile(0.75, axis=1).dropna()

    py_median = py_conv.median(axis=1).dropna()
    py_q25 = py_conv.quantile(0.25, axis=1).dropna()
    py_q75 = py_conv.quantile(0.75, axis=1).dropna()

    min_conv_len = min(
        len(r_median), len(py_median), len(r_q25), len(r_q75), len(py_q25), len(py_q75)
    )
    r_median = r_median.iloc[:min_conv_len]
    r_q25 = r_q25.iloc[:min_conv_len]
    r_q75 = r_q75.iloc[:min_conv_len]
    py_median = py_median.iloc[:min_conv_len]
    py_q25 = py_q25.iloc[:min_conv_len]
    py_q75 = py_q75.iloc[:min_conv_len]

    x_values = range(min_conv_len)

    ax1.plot(x_values, r_median.values, "b-", label="R Implementation", linewidth=2)
    ax1.fill_between(x_values, r_q25.values, r_q75.values, alpha=0.3, color="blue")

    ax1.plot(
        x_values, py_median.values, "r-", label="Python Implementation", linewidth=2
    )
    ax1.fill_between(x_values, py_q25.values, py_q75.values, alpha=0.3, color="red")

    ax1.set_yscale("log")
    ax1.set_xlabel("Iterations")
    ax1.set_ylabel("Best Fitness")
    ax1.set_title(f"Convergence Comparison: CEC2017 F{function_id} (10D)")
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    #  Box plot comparison
    data_to_plot = [
        r_summary["final_fitness"].values,
        py_summary["final_fitness"].values,
    ]
    box_plot = ax2.boxplot(
        data_to_plot, labels=["R Implementation", "Python Implementation"]
    )
    ax2.set_ylabel("Final Best Fitness")
    ax2.set_title("Final Results Distribution")
    ax2.set_yscale("log")
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(
        f"r_vs_python_comparison_f{function_id}.png", dpi=300, bbox_inches="tight"
    )
    plt.show()

    from scipy.stats import wilcoxon

    statistic, p_value = wilcoxon(
        r_summary["final_fitness"].values, py_summary["final_fitness"].values
    )

    print(f"\n=== STATISTICAL COMPARISON ===")
    print(f"Wilcoxon signed-rank test:")
    print(f"Statistic: {statistic}")
    print(f"P-value: {p_value}")
    print(f"Significant difference: {'Yes' if float(p_value) < 0.05 else 'No'}")

    print(f"\nR Implementation - Median: {r_summary['final_fitness'].median():.6e}")
    print(f"Python Implementation - Median: {py_summary['final_fitness'].median():.6e}")


create_comparison_plots(10)
