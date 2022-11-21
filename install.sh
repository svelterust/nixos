#!/usr/bin/env bash

git clone --bare git@git.sr.ht:~knarkzel/dotfiles /home/odd/.cfg
git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ checkout -f
git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ config status.showUntrackedFiles no
mkdir -p /home/odd/downloads
mkdir -p /home/odd/source
