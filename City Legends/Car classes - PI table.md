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
| Velocité Noir Éclair Super Sport | $13,000,000 | X | 933 | X 999 |
| Velocité Noir Éclair | $9,500,000 | X | 916 | X 991 |
| Velocité Noir Éclair Pure | $11,000,000 | X | 911 | X 970 |
| Velocité Noir Origine Super Sport | $6,500,000 | R | 890 | X 966 |
| Speedmark P11 Top | $1,360,000 | R | 862 | X 911 |
| Velocité Noir Origine Roadster Vitesse | $8,500,000 | R | 860 | X 938 |
| Enfurecido L140 Leggera Top | $1,275,000 | R | 845 | R 900 |
| Velocité Noir Origine | $5,000,000 | R | 842 | X 920 |
| Enfurecido LB834 ZVX | $4,200,000 | R | 841 | R 893 |
| Enfurecido LB834 ZVX 63 | $5,500,000 | R | 837 | R 886 |
| Rosso Rampante F142 Top | $1,530,000 | R | 829 | R 878 |
| Stuttgart 991.2 Track Top | $1,700,000 | R | 826 | R 870 |
| Enfurecido LB834 ZV | $3,500,000 | R | 822 | R 884 |
| Enfurecido Murcielago LP640 Top | $3,060,000 | R | 819 | R 881 |
| Stealth-Apex V10 Halo Top | $5,100,000 | R | 819 | R 862 |
| Speedmark P11 Sport | $1,040,000 | R | 809 | R 867 |
| Enfurecido L140 Leggera Sport | $975,000 | R | 806 | R 871 |
| Stuttgart 991.2 Track Sport | $1,300,000 | S2 | 797 | R 839 |
| Rosso Rampante F142 Sport | $1,170,000 | S2 | 790 | R 849 |
| Rosso Rampante F141 Top | $1,445,000 | S2 | 787 | R 855 |
| Enfurecido LB834 | $2,200,000 | S2 | 786 | R 860 |
| Tri-Star Silber C197 Wingdoor Top | $1,615,000 | S2 | 784 | R 845 |
| Stealth-Apex V10 Halo Sport | $3,900,000 | S2 | 782 | R 834 |
| Enfurecido Murcielago LP640 Sport | $2,340,000 | S2 | 780 | R 851 |
| Rosso Rampante F131 Top | $1,020,000 | S2 | 776 | R 838 |
| Speedmark P11 | $800,000 | S2 | 771 | R 838 |
| Enfurecido L140 Leggera | $750,000 | S2 | 759 | R 832 |
| Tri-Star Silber R230 V12 Track Top | $1,190,000 | S2 | 757 | R 830 |
| Stuttgart 991.2 Track | $1,000,000 | S1 | 749 | X 923 |
| Rosso Rampante F141 Sport | $1,105,000 | S1 | 749 | X 952 |
| Stuttgart 971 Turbo S Top | $510,000 | S1 | 746 | X 941 |
| Rosso Rampante F142 | $900,000 | S1 | 743 | X 934 |
| British Vanguard Vela V12 Top | $850,000 | S1 | 743 | X 944 |
| Rosso Rampante F131 Sport | $780,000 | S1 | 739 | X 934 |
| Stealth-Apex V10 Halo | $3,000,000 | S1 | 737 | X 922 |
| Golden Sting 7 Top | $190,000 | S1 | 737 | X 930 |
| Tri-Star Silber C197 Wingdoor Sport | $1,235,000 | S1 | 737 | X 933 |
| Golden Six Supercharged Top | $61,000 | S1 | 733 | X 935 |
| Enfurecido Murcielago LP640 | $1,800,000 | S1 | 732 | X 935 |
| Stuttgart 982 Top | $156,000 | S1 | 727 | R 900 |
| British Vanguard Vanta V12 Top | $765,000 | S1 | 721 | X 927 |
| Rosso Rampante F149 Riviera Top | $1,105,000 | S1 | 716 | X 910 |
| HyperSpeed Tech S7 Top | $204,000 | S1 | 712 | R 899 |
| Tri-Star Silber R230 V12 Track Sport | $910,000 | S1 | 711 | X 915 |
| Ironclad Supercharged Top | $544,000 | S1 | 709 | X 915 |
| Precision Type 42 V10 Top | $935,000 | S1 | 708 | R 894 |
| British Vanguard Vela V12 Sport | $650,000 | S1 | 705 | X 908 |
| Rosso Rampante F141 | $850,000 | S1 | 703 | X 907 |
| Horizon R35 | $420,000 | A | 700 | X 901 |
| Rosso Rampante F131 | $600,000 | A | 695 | R 895 |
| Tri-Star Silber C197 Wingdoor | $950,000 | A | 694 | R 895 |
| Golden Sting 7 Sport | $146,000 | A | 693 | R 893 |
| Stuttgart 971 Turbo S Sport | $390,000 | A | 693 | R 897 |
| Golden Six Supercharged Sport | $47,000 | A | 689 | R 890 |
| Tri-Star Silber C218 V8 S Top | $272,000 | A | 687 | R 891 |
| Stuttgart 982 Sport | $120,000 | A | 686 | R 866 |
| Bavarica Werkz F80 Top | $187,000 | A | 683 | R 883 |
| British Vanguard Vanta V12 Sport | $585,000 | A | 676 | R 879 |
| Sovereign Grand Tourer Top | $1,870,000 | A | 674 | R 881 |
| Ironclad Supercharged Sport | $416,000 | A | 672 | R 876 |
| Rosso Rampante F149 Riviera Sport | $845,000 | A | 671 | R 873 |
| HyperSpeed Tech S7 Sport | $156,000 | A | 671 | R 865 |
| Enfurecido Brava Top | $2,550,000 | A | 669 | R 874 |
| Tri-Star Silber R230 V12 Track | $700,000 | A | 668 | R 871 |
| Precision Type 42 V10 Sport | $715,000 | A | 667 | R 861 |
| Bavarica Werkz F90 | $165,000 | A | 661 | R 862 |
| British Vanguard Vela V12 | $500,000 | A | 660 | R 861 |
| Bavarica Werkz F93 Fastback | $210,000 | A | 655 | R 856 |
| Stuttgart 971 Turbo S | $300,000 | A | 654 | R 857 |
| Tri-Star Silber C218 V8 S Sport | $208,000 | A | 651 | R 852 |
| Golden Sting 7 | $112,000 | A | 651 | R 849 |
| Golden Six Supercharged | $36,000 | A | 648 | R 848 |
| Stuttgart 982 | $92,000 | A | 646 | R 835 |
| Enfurecido Classico 400 Top | $4,250,000 | A | 644 | R 845 |
| Bavarica Werkz F80 Sport | $143,000 | A | 641 | R 840 |
| Tri-Star Silber W213 V8 S | $175,000 | A | 639 | R 839 |
| Sovereign Grand Tourer Sport | $1,430,000 | A | 638 | R 842 |
| British Vanguard Vanta V12 | $450,000 | A | 633 | R 835 |
| HyperSpeed Tech S7 | $120,000 | A | 633 | R 831 |
| Stealth-Apex Z100 V8 Top | $408,000 | A | 633 | R 834 |
| Enfurecido Brava Sport | $1,950,000 | A | 633 | R 836 |
| Rosso Rampante F149 Riviera | $650,000 | A | 629 | R 830 |
| Ironclad Supercharged | $320,000 | A | 628 | R 830 |
| Ahura FD Rotary Top | $71,000 | A | 623 | R 817 |
| Precision Type 42 V10 | $550,000 | A | 621 | R 820 |
| Trident Motors Maestrale GTS Top | $323,000 | A | 615 | R 818 |
| Apex JZA80 Top | $238,000 | A | 614 | R 816 |
| Tri-Star Silber C218 V8 S | $160,000 | A | 607 | R 807 |
| Ironclad LC V8 Top | $196,000 | A | 606 | R 807 |
| Bavarica Werkz F82 | $100,000 | A | 604 | R 802 |
| Enfurecido Classico 400 Sport | $3,250,000 | A | 602 | R 802 |
| Bavarica Werkz F80 | $110,000 | A | 601 | S2 798 |
| Bavarica Werkz F10 | $145,000 | B | 596 | S2 797 |
| Sovereign Grand Tourer | $1,100,000 | B | 593 | S2 797 |
| Stealth-Apex Z100 V8 Sport | $312,000 | B | 593 | S2 793 |
| British Vanguard Highland Top | $765,000 | B | 590 | S2 793 |
| Ecstasy Nocturne Top | $3,400,000 | B | 589 | S2 788 |
| Enfurecido Brava | $1,500,000 | B | 588 | S2 790 |
| Ahura FD Rotary Sport | $55,000 | B | 587 | S2 782 |
| Sovereign Highlands Top | $2,040,000 | B | 586 | S2 791 |
| Bavarica Werkz E63 V10 | $135,000 | B | 576 | S2 777 |
| Dream-Build Volt Titan Top | $493,000 | B | 576 | S2 761 |
| Apex JZA80 Sport | $182,000 | B | 575 | S2 775 |
| Horizon Z33 Top | $65,000 | B | 574 | S2 770 |
| Trident Motors Maestrale GTS Sport | $247,000 | B | 572 | S2 774 |
| Bavarica Werkz E60 V10 | $125,000 | B | 570 | S2 770 |
| Apex JZX100 Tourer Top | $51,000 | B | 566 | S2 762 |
| Ironclad LC V8 Sport | $150,000 | B | 564 | S2 764 |
| Enfurecido Classico 400 | $2,500,000 | B | 563 | S2 762 |
| Tri-Star Silber W222 V12 | $280,000 | B | 563 | S2 759 |
| Bavarica Werkz E92 V8 | $90,000 | B | 561 | S2 757 |
| British Vanguard Highland Sport | $585,000 | B | 549 | S2 751 |
| Ecstasy Nocturne Sport | $2,600,000 | B | 549 | S1 747 |
| Stealth-Apex Z100 V8 | $240,000 | B | 548 | S1 746 |
| Ahura FD Rotary | $42,000 | B | 546 | S1 740 |
| Bavarica Werkz G12 Long Top | $255,000 | B | 544 | S1 742 |
| Dream-Build Volt Titan Sport | $377,000 | B | 543 | S1 728 |
| Sovereign Highlands Sport | $1,560,000 | B | 542 | S1 745 |
| Tri-Star Silber W201 Evo II Top | $136,000 | B | 542 | S1 738 |
| Horizon BNR34 | $180,000 | B | 534 | S1 730 |
| Trident Motors Maestrale GTS | $190,000 | B | 532 | S1 731 |
| Horizon Z33 Sport | $49,000 | B | 532 | S1 728 |
| Apex JZA80 | $140,000 | B | 530 | S1 728 |
| Apex JZX100 Tourer Sport | $39,000 | B | 526 | S1 721 |
| Ironclad LC V8 | $115,000 | B | 525 | S1 724 |
| Bavarica Werkz G07 Top | $298,000 | B | 512 | S1 711 |
| Tri-Star Silber X167 Royale Top | $2,040,000 | B | 510 | S1 710 |
| British Vanguard Highland | $450,000 | B | 510 | S1 711 |
| Bavarica Werkz G12 Long Sport | $195,000 | B | 507 | S1 704 |
| Ecstasy Nocturne | $2,000,000 | B | 504 | S1 701 |
| Dream-Build Volt Titan | $290,000 | B | 503 | A 686 |
| Tri-Star Silber Z223 Royale V12 | $1,600,000 | B | 502 | A 699 |
| Sovereign Highlands | $1,200,000 | B | 502 | S1 703 |
| Tri-Star Silber W201 Evo II Sport | $104,000 | B | 502 | A 696 |
| Rocket W463 800 | $1,600,000 | C | 497 | A 694 |
| Tri-Star Silber C167 3.0 Top | $425,000 | C | 496 | A 695 |
| Horizon Z33 | $38,000 | C | 493 | A 688 |
| Apex JZX100 Tourer | $30,000 | C | 487 | A 682 |
| Ecstasy Grandeur Top | $4,250,000 | C | 486 | A 686 |
| Tri-Star Silber W221 V8 | $140,000 | C | 484 | A 681 |
| Bavarica Werkz G07 Sport | $228,000 | C | 473 | A 671 |
| Tri-Star Silber X167 Royale Sport | $1,560,000 | C | 473 | A 672 |
| Bavarica Werkz G30 3.0 | $42,000 | C | 469 | A 664 |
| Bavarica Werkz G12 Long | $150,000 | C | 464 | A 660 |
| Tri-Star Silber C167 3.0 Sport | $325,000 | C | 459 | A 657 |
| Tri-Star Silber W201 Evo II | $80,000 | C | 459 | A 652 |
| Bavarica Werkz G06 Sport Top | $221,000 | C | 453 | A 652 |
| Tri-Star Silber W213 3.0 | $85,000 | C | 448 | A 643 |
| Ecstasy Grandeur Sport | $3,250,000 | C | 443 | A 642 |
| Tri-Star Silber X167 Royale | $1,200,000 | C | 431 | A 629 |
| Bavarica Werkz G07 | $175,000 | C | 429 | A 626 |
| Tri-Star Silber W463 V8 | $260,000 | C | 420 | A 616 |
| Tri-Star Silber C167 3.0 | $250,000 | C | 418 | A 615 |
| Bavarica Werkz G06 Sport Sport | $169,000 | C | 410 | A 608 |
| Ecstasy Grandeur | $2,500,000 | C | 402 | B 600 |
| Apex Cambria Top | $27,000 | D | 388 | B 582 |
| Stealth-Apex J310 Top | $417,000 | D | 382 | B 579 |
| Bavarica Werkz G06 Sport | $130,000 | D | 370 | B 567 |
| Apex Cambria Sport | $21,000 | D | 351 | B 544 |
| Stealth-Apex J310 Sport | $319,000 | D | 340 | B 536 |
| Apex Cambria | $16,000 | D | 311 | B 502 |
| Apex J300 | $150,000 | D | 305 | C 499 |
| Stealth-Apex J310 | $245,000 | D | 301 | C 495 |
| Apex Grand Lounge Top | $48,000 | D | 275 | C 467 |
| Orient Voltra Top | $15,000 | D | 274 | C 462 |
| Apex J200 | $35,000 | D | 263 | C 457 |
| Orient Voltra Sport | $8,000 | D | 240 | C 427 |
| Apex Grand Lounge Sport | $36,000 | D | 238 | C 429 |
| Orient Voltra | $0 | D | 200 | D 387 |
| Apex Grand Lounge | $28,000 | D | 198 | D 387 |
