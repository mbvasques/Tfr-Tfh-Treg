#!/bin/bash
#SBATCH --job-name=pyscenic_job
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=mariana.vasques@gimm.pt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=128gb
#SBATCH --time=5-00:00:00
#SBATCH --output=pyscenic_pipeline_%j.log
#SBATCH --error=pyscenic_pipeline_%j.err
#SBATCH --chdir=/data/Users/marianavasques

pwd; hostname; date

# Mount shared data path
export SINGULARITY_BIND="/ifs"

# Define variables for paths to avoid repetition
LOOM_IN="analysis/pyscenic/integration_counts_scenic.loom"
TF_FILE="analysis/pyscenic/allTFs_mm.txt"
ADJACENCIES="analysis/pyscenic/pyscenic_adj.tsv"
RANK_DB="analysis/pyscenic/mm10_500bp_up_100bp_down_full_tx_v10_clust.genes_vs_motifs.rankings.feather"
MOTIF_DB="analysis/pyscenic/motifs-v10nr_clust-nr.mgi-m0.001-o0.0.tbl.txt"
REGULONS="analysis/pyscenic/regulons.csv"
AUCELL_OUTPUT="analysis/pyscenic/pyscenic_output.loom"

# Step 1: GRN inference
singularity run aertslab-pyscenic-0.12.1.sif \
  pyscenic grn $LOOM_IN $TF_FILE \
  -o $ADJACENCIES \
  --num_workers 6 \
  --seed 13

# Step 2: Motif enrichment (ctx)
singularity run aertslab-pyscenic-0.12.1.sif \
  pyscenic ctx $ADJACENCIES \
  $RANK_DB \
  --annotations_fname $MOTIF_DB \
  --expression_mtx_fname $LOOM_IN \
  --output $REGULONS \
  --mask_dropouts \
  --num_workers 6

# Step 3: AUCell scoring
singularity run aertslab-pyscenic-0.12.1.sif \
  pyscenic aucell \
  $LOOM_IN \
  $REGULONS \
  --output $AUCELL_OUTPUT \
  --num_workers 6

date