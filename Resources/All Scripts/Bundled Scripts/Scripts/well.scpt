FasdUAS 1.101.10   ��   ��    k             l     ��  ��    B < Portions of this AppleScript may incorporate work from 3rd      � 	 	 x   P o r t i o n s   o f   t h i s   A p p l e S c r i p t   m a y   i n c o r p o r a t e   w o r k   f r o m   3 r d     
  
 l     ��  ��    D > parties. These portions of code are noted. All other work is      �   |   p a r t i e s .   T h e s e   p o r t i o n s   o f   c o d e   a r e   n o t e d .   A l l   o t h e r   w o r k   i s        l     ��  ��    ; 5 Copyright � 2010 � 2013 Codeux Software. See README      �   j   C o p y r i g h t   �   2 0 1 0      2 0 1 3   C o d e u x   S o f t w a r e .   S e e   R E A D M E        l     ��  ��    %  for full license information.      �   >   f o r   f u l l   l i c e n s e   i n f o r m a t i o n .        l     ��������  ��  ��        i         I      �� ���� 0 
textualcmd       !   o      ���� 0 args   !  "�� " o      ���� (0 destinationchannel destinationChannel��  ��    k     � # #  $ % $ Z      & '���� & =     ( ) ( o     ���� (0 destinationchannel destinationChannel ) m     * * � + +   ' L     , , m     - - � . . F / d e b u g   I n v a l i d   d e s t i n a t i o n   c h a n n e l .��  ��   %  / 0 / l   ��������  ��  ��   0  1 2 1 l   �� 3 4��   3 E ? This is just the improved /slap script dgw edited, but changed    4 � 5 5 ~   T h i s   i s   j u s t   t h e   i m p r o v e d   / s l a p   s c r i p t   d g w   e d i t e d ,   b u t   c h a n g e d 2  6 7 6 l   �� 8 9��   8 < 6 to throw things down a well instead. Yeah, it's lazy.    9 � : : l   t o   t h r o w   t h i n g s   d o w n   a   w e l l   i n s t e a d .   Y e a h ,   i t ' s   l a z y . 7  ; < ; l   ��������  ��  ��   <  = > = r     ? @ ? I    �� A���� 0 trim   A  B�� B o    ���� 0 args  ��  ��   @ o      ���� 0 args   >  C D C l   ��������  ��  ��   D  E F E r    ! G H G I   ���� I
�� .sysooffslong    ��� null��   I �� J K
�� 
psof J m     L L � M M    K �� N��
�� 
psin N o    ���� 0 args  ��   H o      ���� 0 	spacechar 	spaceChar F  O P O Z   " i Q R�� S Q >  " % T U T o   " #���� 0 	spacechar 	spaceChar U m   # $����   R k   ( _ V V  W X W r   ( 7 Y Z Y n   ( 5 [ \ [ 7  ) 5�� ] ^
�� 
ctxt ] m   - /����  ^ l  0 4 _���� _ \   0 4 ` a ` o   1 2���� 0 	spacechar 	spaceChar a m   2 3���� ��  ��   \ o   ( )���� 0 args   Z o      ���� 	0 thing   X  b c b r   8 E d e d n   8 C f g f 7  9 C�� h i
�� 
ctxt h l  = ? j���� j o   = ?���� 0 	spacechar 	spaceChar��  ��   i m   @ B������ g o   8 9���� 0 args   e o      ���� 
0 reason   c  k�� k Z   F _ l m���� l F   F S n o n l  F J p���� p H   F J q q C   F I r s r o   F G���� 
0 reason   s m   G H t t � u u    b e c a u s e��  ��   o l  M Q v���� v H   M Q w w C   M P x y x o   M N���� 
0 reason   y m   N O z z � { {    f o r��  ��   m r   V [ | } | b   V Y ~  ~ m   V W � � � � �  :  o   W X���� 
0 reason   } o      ���� 
0 reason  ��  ��  ��  ��   S k   b i � �  � � � r   b e � � � o   b c���� 0 args   � o      ���� 	0 thing   �  ��� � r   f i � � � m   f g � � � � �   � o      ���� 
0 reason  ��   P  � � � Z   j v � ����� � =  j m � � � o   j k���� 0 args   � m   k l � � � � �   � L   p r � � m   p q � � � � � / d e b u g   U s e :   / w e l l   [ o b j e c t   [ r e a s o n ] ] .   T h e   r e a s o n   i s   o p t i o n a l ,   b u t   i f   s p e c i f i e d ,   l e t s   y o u   e x p l a i n   w h y   y o u ' r e   t h r o w i n g   [ o b j e c t ]   d o w n   a   w e l l .��  ��   �  � � � l  w w��������  ��  ��   �  ��� � L   w � � � b   w � � � � b   w � � � � b   w � � � � b   w � � � � b   w | � � � m   w z � � � � � 
 / s m e   � o   z {���� (0 destinationchannel destinationChannel � m   |  � � � � �    t h r o w s   � o   � ����� 	0 thing   � m   � � � � � � �    d o w n   a   w e l l � o   � ����� 
0 reason  ��     � � � l     ��������  ��  ��   �  � � � l     �� � ���   � ( " trim() AppleScript function from:    � � � � D   t r i m ( )   A p p l e S c r i p t   f u n c t i o n   f r o m : �  � � � l     �� � ���   � 6 0 <http://macscripter.net/viewtopic.php?id=18519>    � � � � `   < h t t p : / / m a c s c r i p t e r . n e t / v i e w t o p i c . p h p ? i d = 1 8 5 1 9 > �  � � � i     � � � I      �� ����� 0 trim   �  ��� � o      ���� 0 sometext someText��  ��   � k     : � �  � � � W      � � � r   	  � � � n   	  � � � 7  
 �� � �
�� 
ctxt � m    ����  � m    ������ � o   	 
���� 0 sometext someText � o      ���� 0 sometext someText � H     � � C     � � � o    ���� 0 sometext someText � m     � � � � �    �  � � � l   ��������  ��  ��   �  � � � W    7 � � � r   % 2 � � � n   % 0 � � � 7  & 0�� � �
�� 
ctxt � m   * ,����  � m   - /������ � o   % &���� 0 sometext someText � o      ���� 0 sometext someText � H     $ � � D     # � � � o     !���� 0 sometext someText � m   ! " � � � � �    �  � � � l  8 8��������  ��  ��   �  ��� � L   8 : � � o   8 9���� 0 sometext someText��   �  ��� � l     ��������  ��  ��  ��       �� � � ���   � ������ 0 
textualcmd  �� 0 trim   � �� ���� � ����� 0 
textualcmd  �� �� ���  �  ������ 0 args  �� (0 destinationchannel destinationChannel��   � ��������~�� 0 args  �� (0 destinationchannel destinationChannel�� 0 	spacechar 	spaceChar� 	0 thing  �~ 
0 reason   �  * -�}�| L�{�z�y�x t z�w � � � � � � ��} 0 trim  
�| 
psof
�{ 
psin�z 
�y .sysooffslong    ��� null
�x 
ctxt
�w 
bool�� ���  �Y hO*�k+ E�O*���� E�O�j <�[�\[Zk\Z�k2E�O�[�\[Z�\Zi2E�O��	 ���& 
�%E�Y hY 	�E�O�E�O��  �Y hOa �%a %�%a %�% � �v ��u�t � ��s�v 0 trim  �u �r ��r  �  �q�q 0 sometext someText�t   � �p�p 0 sometext someText �  ��o ��n
�o 
ctxt�n���s ; h���[�\[Zl\Zi2E�[OY��O h���[�\[Zk\Z�2E�[OY��O�ascr  ��ޭ