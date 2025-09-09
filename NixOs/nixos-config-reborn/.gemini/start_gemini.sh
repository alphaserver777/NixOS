#!/usr/bin/env bash
gcloud config set project nixos-ai-001
gcloud config get-value project
gcloud services enable cloudaicompanion.googleapis.com --project=nixos-ai-001
gcloud services list --enabled --project=nixos-ai-001 | grep cloudaicompanion
export GOOGLE_CLOUD_PROJECT=nixos-ai-001

