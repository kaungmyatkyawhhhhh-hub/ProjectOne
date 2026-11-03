# Car classes: every car's PI (2026-11-03)

How the Performance Index (PI) is worked out (`CarStats.pi`, numbers in `Config.CarClasses`):
- Six numbers, each scored 0 to 1 on its own range, then added with these weights:
  - **power-to-weight** 40% (real hp per tonne; 90 hp/t scores 0, 800 scores 1, log scale)
  - **0-60 mph** 20% (11 s scores 0, 2.2 s scores 1, log scale)
  - **handling** 17% (0.45 to 0.97)
  - **top speed** 12% (90 to 275 mph, counts more near the top)
  - **weight** 6% (2,800 kg scores 0, 1,200 kg scores 1)
  - **braking** 5%
- The total becomes 100-999 (`Map`), then the parts add their share (the flywheel takes a little off).
- Classes (owner picked the suggested ranges): **D 100-400, C 401-500, B 501-600, A 601-700, S1 701-750, S2 751-800, R 801-900, X 901-999.**
- Only the three Chirouns are X (they need player level 60 at the dealer); everything else costs money only.
- Stock S2 / R / X cars can only fit tyres, gearbox, suspension and exhaust (owner).
- "All parts" = every part the car can take, at Race.
- Re-make this table: `lune run tools/pi_table.luau . --md` (from `Games/CityLegends`).

170 cars: D 15, C 21, B 42, A 44, S1 20, S2 11, R 14, X 3

| Car | Price | Class | PI | All parts (Race) |
|---|---|---|---|---|
| Velocité Noir Chiroun Super Sport | $13,000,000 | X | 933 | X 999 |
| Velocité Noir Chiroun | $9,500,000 | X | 916 | X 991 |
| Velocité Noir Chiroun Pur Sport | $11,000,000 | X | 911 | X 970 |
| Velocité Noir Veyrun Super Sport | $6,500,000 | R | 890 | X 966 |
| Speedmark MP4-12C Top | $1,360,000 | R | 862 | X 911 |
| Velocité Noir Veyrun Grand Sport Vitesse | $8,500,000 | R | 860 | X 938 |
| Enfurecido Gallardo LP570-4 SL Top | $1,275,000 | R | 845 | R 900 |
| Velocité Noir Veyrun 16.4 | $5,000,000 | R | 842 | X 920 |
| Enfurecido Aventador SVJ | $4,200,000 | R | 841 | R 893 |
| Enfurecido Aventador SVJ 63 | $5,500,000 | R | 837 | R 886 |
| Rosso Rampante 458 Itala Top | $1,530,000 | R | 829 | R 878 |
| Stuttgart 911 GT3 991.2 Top | $1,700,000 | R | 826 | R 870 |
| Enfurecido Aventador SV LP750-4 | $3,500,000 | R | 822 | R 884 |
| Enfurecido Murcielago LP640 Top | $3,060,000 | R | 819 | R 881 |
| Stealth-Apex LFA Top | $5,100,000 | R | 819 | R 862 |
| Speedmark MP4-12C Sport | $1,040,000 | R | 809 | R 867 |
| Enfurecido Gallardo LP570-4 SL Sport | $975,000 | R | 806 | R 871 |
| Stuttgart 911 GT3 991.2 Sport | $1,300,000 | S2 | 797 | R 839 |
| Rosso Rampante 458 Itala Sport | $1,170,000 | S2 | 790 | R 849 |
| Rosso Rampante 599 Top | $1,445,000 | S2 | 787 | R 855 |
| Enfurecido Aventador LP700-4 | $2,200,000 | S2 | 786 | R 860 |
| Tri-Star Silber SLS Top | $1,615,000 | S2 | 784 | R 845 |
| Stealth-Apex LFA Sport | $3,900,000 | S2 | 782 | R 834 |
| Enfurecido Murcielago LP640 Sport | $2,340,000 | S2 | 780 | R 851 |
| Rosso Rampante F430 Top | $1,020,000 | S2 | 776 | R 838 |
| Speedmark MP4-12C | $800,000 | S2 | 771 | R 838 |
| Enfurecido Gallardo LP570-4 SL | $750,000 | S2 | 759 | R 832 |
| Tri-Star Silber SL65 Black Series Top | $1,190,000 | S2 | 757 | R 830 |
| Stuttgart 911 GT3 991.2 | $1,000,000 | S1 | 749 | X 923 |
| Rosso Rampante 599 Sport | $1,105,000 | S1 | 749 | X 952 |
| Stuttgart Panamera Turbo S Top | $510,000 | S1 | 746 | X 941 |
| Rosso Rampante 458 Itala | $900,000 | S1 | 743 | X 934 |
| British Vanguard Vantage Top | $850,000 | S1 | 743 | X 944 |
| Rosso Rampante F430 Sport | $780,000 | S1 | 739 | X 934 |
| Stealth-Apex LFA | $3,000,000 | S1 | 737 | X 922 |
| Golden Corvette C7 Top | $190,000 | S1 | 737 | X 930 |
| Tri-Star Silber SLS Sport | $1,235,000 | S1 | 737 | X 933 |
| Golden Camaro ZL1 Top | $61,000 | S1 | 733 | X 935 |
| Enfurecido Murcielago LP640 | $1,800,000 | S1 | 732 | X 935 |
| Stuttgart Boxster 718 Top | $156,000 | S1 | 727 | R 900 |
| British Vanguard Vanquish Top | $765,000 | S1 | 721 | X 927 |
| Rosso Rampante Californa Top | $1,105,000 | S1 | 716 | X 910 |
| HyperSpeed Tech SU7 Top | $204,000 | S1 | 712 | R 899 |
| Tri-Star Silber SL65 Black Series Sport | $910,000 | S1 | 711 | X 915 |
| Hemi SRT Top | $544,000 | S1 | 709 | X 915 |
| Precision R8 Type 42 Top | $935,000 | S1 | 708 | R 894 |
| British Vanguard Vantage Sport | $650,000 | S1 | 705 | X 908 |
| Rosso Rampante 599 | $850,000 | S1 | 703 | X 907 |
| Horizon GT-R R35 | $420,000 | A | 700 | X 901 |
| Rosso Rampante F430 | $600,000 | A | 695 | R 895 |
| Tri-Star Silber SLS | $950,000 | A | 694 | R 895 |
| Golden Corvette C7 Sport | $146,000 | A | 693 | R 893 |
| Stuttgart Panamera Turbo S Sport | $390,000 | A | 693 | R 897 |
| Golden Camaro ZL1 Sport | $47,000 | A | 689 | R 890 |
| Tri-Star Silber CLS 63 S Top | $272,000 | A | 687 | R 891 |
| Stuttgart Boxster 718 Sport | $120,000 | A | 686 | R 866 |
| Bavarica Werkz M3 F80 Top | $187,000 | A | 683 | R 883 |
| British Vanguard Vanquish Sport | $585,000 | A | 676 | R 879 |
| Sovereign Continental GT Top | $1,870,000 | A | 674 | R 881 |
| Hemi SRT Sport | $416,000 | A | 672 | R 876 |
| Rosso Rampante Californa Sport | $845,000 | A | 671 | R 873 |
| HyperSpeed Tech SU7 Sport | $156,000 | A | 671 | R 865 |
| Enfurecido Urus Top | $2,550,000 | A | 669 | R 874 |
| Tri-Star Silber SL65 Black Series | $700,000 | A | 668 | R 871 |
| Precision R8 Type 42 Sport | $715,000 | A | 667 | R 861 |
| Bavarica Werkz M5 F90 | $165,000 | A | 661 | R 862 |
| British Vanguard Vantage | $500,000 | A | 660 | R 861 |
| Bavarica Werkz M8 Gran Coupe | $210,000 | A | 655 | R 856 |
| Stuttgart Panamera Turbo S | $300,000 | A | 654 | R 857 |
| Tri-Star Silber CLS 63 S Sport | $208,000 | A | 651 | R 852 |
| Golden Corvette C7 | $112,000 | A | 651 | R 849 |
| Golden Camaro ZL1 | $36,000 | A | 648 | R 848 |
| Stuttgart Boxster 718 | $92,000 | A | 646 | R 835 |
| Enfurecido Countach LP400S Top | $4,250,000 | A | 644 | R 845 |
| Bavarica Werkz M3 F80 Sport | $143,000 | A | 641 | R 840 |
| Tri-Star Silber E63 S | $175,000 | A | 639 | R 839 |
| Sovereign Continental GT Sport | $1,430,000 | A | 638 | R 842 |
| British Vanguard Vanquish | $450,000 | A | 633 | R 835 |
| HyperSpeed Tech SU7 | $120,000 | A | 633 | R 831 |
| Stealth-Apex LC500 Top | $408,000 | A | 633 | R 834 |
| Enfurecido Urus Sport | $1,950,000 | A | 633 | R 836 |
| Rosso Rampante Californa | $650,000 | A | 629 | R 830 |
| Hemi SRT | $320,000 | A | 628 | R 830 |
| Ahura RX-7 Top | $71,000 | A | 623 | R 817 |
| Precision R8 Type 42 | $550,000 | A | 621 | R 820 |
| Trident Motors Levanto GTS Top | $323,000 | A | 615 | R 818 |
| Apex Supro MK4 Top | $238,000 | A | 614 | R 816 |
| Tri-Star Silber CLS 63 S | $160,000 | A | 607 | R 807 |
| Hemi Challenjer Top | $196,000 | A | 606 | R 807 |
| Bavarica Werkz M4 F82 | $100,000 | A | 604 | R 802 |
| Enfurecido Countach LP400S Sport | $3,250,000 | A | 602 | R 802 |
| Bavarica Werkz M3 F80 | $110,000 | A | 601 | S2 798 |
| Bavarica Werkz M5 F10 | $145,000 | B | 596 | S2 797 |
| Sovereign Continental GT | $1,100,000 | B | 593 | S2 797 |
| Stealth-Apex LC500 Sport | $312,000 | B | 593 | S2 793 |
| British Vanguard DBX Top | $765,000 | B | 590 | S2 793 |
| Ecstasy Wraith Top | $3,400,000 | B | 589 | S2 788 |
| Enfurecido Urus | $1,500,000 | B | 588 | S2 790 |
| Ahura RX-7 Sport | $55,000 | B | 587 | S2 782 |
| Sovereign Bentayga Top | $2,040,000 | B | 586 | S2 791 |
| Bavarica Werkz M6 V10 | $135,000 | B | 576 | S2 777 |
| Dream-Build Volt Yangwong U8 Top | $493,000 | B | 576 | S2 761 |
| Apex Supro MK4 Sport | $182,000 | B | 575 | S2 775 |
| Horizon 350Z Top | $65,000 | B | 574 | S2 770 |
| Trident Motors Levanto GTS Sport | $247,000 | B | 572 | S2 774 |
| Bavarica Werkz M5 E60 V10 | $125,000 | B | 570 | S2 770 |
| Apex Chasor Tourer V Top | $51,000 | B | 566 | S2 762 |
| Hemi Challenjer Sport | $150,000 | B | 564 | S2 764 |
| Enfurecido Countach LP400S | $2,500,000 | B | 563 | S2 762 |
| Tri-Star Silber S65 W222 | $280,000 | B | 563 | S2 759 |
| Bavarica Werkz M3 E92 | $90,000 | B | 561 | S2 757 |
| British Vanguard DBX Sport | $585,000 | B | 549 | S2 751 |
| Ecstasy Wraith Sport | $2,600,000 | B | 549 | S1 747 |
| Stealth-Apex LC500 | $240,000 | B | 548 | S1 746 |
| Ahura RX-7 | $42,000 | B | 546 | S1 740 |
| Bavarica Werkz 750Li Top | $255,000 | B | 544 | S1 742 |
| Dream-Build Volt Yangwong U8 Sport | $377,000 | B | 543 | S1 728 |
| Sovereign Bentayga Sport | $1,560,000 | B | 542 | S1 745 |
| Tri-Star Silber 190E Evo II Top | $136,000 | B | 542 | S1 738 |
| Horizon Skyline R34 GT-R | $180,000 | B | 534 | S1 730 |
| Trident Motors Levanto GTS | $190,000 | B | 532 | S1 731 |
| Horizon 350Z Sport | $49,000 | B | 532 | S1 728 |
| Apex Supro MK4 | $140,000 | B | 530 | S1 728 |
| Apex Chasor Tourer V Sport | $39,000 | B | 526 | S1 721 |
| Hemi Challenjer | $115,000 | B | 525 | S1 724 |
| Bavarica Werkz X7 Top | $298,000 | B | 512 | S1 711 |
| Tri-Star Silber Maybech GLS 600 Top | $2,040,000 | B | 510 | S1 710 |
| British Vanguard DBX | $450,000 | B | 510 | S1 711 |
| Bavarica Werkz 750Li Sport | $195,000 | B | 507 | S1 704 |
| Ecstasy Wraith | $2,000,000 | B | 504 | S1 701 |
| Dream-Build Volt Yangwong U8 | $290,000 | B | 503 | A 686 |
| Tri-Star Silber Maybech S680 | $1,600,000 | B | 502 | A 699 |
| Sovereign Bentayga | $1,200,000 | B | 502 | S1 703 |
| Tri-Star Silber 190E Evo II Sport | $104,000 | B | 502 | A 696 |
| Rocket G63 | $1,600,000 | C | 497 | A 694 |
| Tri-Star Silber GLE 53 Top | $425,000 | C | 496 | A 695 |
| Horizon 350Z | $38,000 | C | 493 | A 688 |
| Apex Chasor Tourer V | $30,000 | C | 487 | A 682 |
| Ecstasy Phantom Top | $4,250,000 | C | 486 | A 686 |
| Tri-Star Silber S63 W221 | $140,000 | C | 484 | A 681 |
| Bavarica Werkz X7 Sport | $228,000 | C | 473 | A 671 |
| Tri-Star Silber Maybech GLS 600 Sport | $1,560,000 | C | 473 | A 672 |
| Bavarica Werkz 540i G30 | $42,000 | C | 469 | A 664 |
| Bavarica Werkz 750Li | $150,000 | C | 464 | A 660 |
| Tri-Star Silber GLE 53 Sport | $325,000 | C | 459 | A 657 |
| Tri-Star Silber 190E Evo II | $80,000 | C | 459 | A 652 |
| Bavarica Werkz X6 M Sport Top | $221,000 | C | 453 | A 652 |
| Tri-Star Silber E400 | $85,000 | C | 448 | A 643 |
| Ecstasy Phantom Sport | $3,250,000 | C | 443 | A 642 |
| Tri-Star Silber Maybech GLS 600 | $1,200,000 | C | 431 | A 629 |
| Bavarica Werkz X7 | $175,000 | C | 429 | A 626 |
| Tri-Star Silber G63 | $260,000 | C | 420 | A 616 |
| Tri-Star Silber GLE 53 | $250,000 | C | 418 | A 615 |
| Bavarica Werkz X6 M Sport Sport | $169,000 | C | 410 | A 608 |
| Ecstasy Phantom | $2,500,000 | C | 402 | B 600 |
| Apex Camri Top | $27,000 | D | 388 | B 582 |
| Stealth-Apex LX700 Top | $417,000 | D | 382 | B 579 |
| Bavarica Werkz X6 M Sport | $130,000 | D | 370 | B 567 |
| Apex Camri Sport | $21,000 | D | 351 | B 544 |
| Stealth-Apex LX700 Sport | $319,000 | D | 340 | B 536 |
| Apex Camri | $16,000 | D | 311 | B 502 |
| Apex Land Cruzer 300 | $150,000 | D | 305 | C 499 |
| Stealth-Apex LX700 | $245,000 | D | 301 | C 495 |
| Apex Alfard Top | $48,000 | D | 275 | C 467 |
| Orient EV6 Top | $15,000 | D | 274 | C 462 |
| Apex Land Cruzer 200 | $35,000 | D | 263 | C 457 |
| Orient EV6 Sport | $8,000 | D | 240 | C 427 |
| Apex Alfard Sport | $36,000 | D | 238 | C 429 |
| Orient EV6 | $0 | D | 200 | D 387 |
| Apex Alfard | $28,000 | D | 198 | D 387 |
