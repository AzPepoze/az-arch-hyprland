#!/bin/bash
playerctl metadata --format "[{{ status }}]  {{ trunc(title, 30) }} - {{ artist }}"