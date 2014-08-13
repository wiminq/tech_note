#TCP三次握手 四次断开

##三次握手
SYN=1;SEQ=client_isn;-->

SYN=1;SEQ=client_isn;ACK=client_isn+1;<--

SYN=0;SEQ=client_isn+1;ACK=server_isn+1;-->

##四次断开
FIN=1;ACK=Z;SEQ=X;-->

ACK=X+1;SEQ=Z;<--

FIN=1;ACK=X;SEQ=Y;<--

ACK=Y;SEQ=X;-->
