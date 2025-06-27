
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is


type state_type is (ST0,ST1,ST2,ST3,ST4,ST5,ST6,ST7,ST8,ST9,ST10,ST11);

signal PS,NS : state_type;

signal area: STD_LOGIC_VECTOR(15 downto 0);
signal current: STD_LOGIC_VECTOR (15 downto 0);
signal last: STD_LOGIC_VECTOR (15 downto 0);
signal colonne: STD_LOGIC_VECTOR(7 downto 0);
signal righe: STD_LOGIC_VECTOR(7 downto 0);
signal rigaPrecedente: STD_LOGIC_VECTOR(7 downto 0);
signal colonnaPrecedente: STD_LOGIC_VECTOR(7 downto 0);
signal rigaCorrente: STD_LOGIC_VECTOR(7 downto 0);
signal colonnaCorrente: STD_LOGIC_VECTOR(7 downto 0);
signal soglia: STD_LOGIC_VECTOR(7 downto 0);
signal rigaMinima: STD_LOGIC_VECTOR(7 downto 0);
signal colonnaMinima: STD_LOGIC_VECTOR(7 downto 0);
signal rigaMassima: STD_LOGIC_VECTOR(7 downto 0);
signal colonnaMassima: STD_LOGIC_VECTOR(7 downto 0); 

begin

sync_proc: process(i_clk,i_rst,i_start)
begin
    if (i_rst'event and i_rst='1')  then
        PS<=ST0;
        end if;
    if (rising_edge(i_clk)) then
        PS<=NS;
    end if;
end process sync_proc;

comb_proc: process(i_rst,i_clk,i_start)
begin  
    case PS is              
        when ST0 =>
            if (i_rst='1') then
                o_done<='0';
                NS<=ST0;
            elsif (i_start='1') then
                NS<=ST1;
            else
                NS<=ST0;
            end if;
        when ST1 =>
        --Inizializza tutti i segnali e chiede il numero di colonne
            rigaMinima <= "UUUUUUUU";
            colonnaMinima <= "UUUUUUUU";
            rigaMassima <= "UUUUUUUU";
            colonnaMassima <= "UUUUUUUU";
            o_address<="0000000000000010";
            o_en<='1';
            o_we<='0';
            NS<=ST2;    
        when ST2 =>
        --prende il valore di numero di colonne e lo salva, quindi chiede quello di righe
            colonne<=i_data;
            o_address<="0000000000000011";
            NS<=ST3;
        when ST3 =>
        --prende il valore del numero di righe e lo salva, quindi chiede il numero di soglia
            righe<=i_data;
            o_address<="0000000000000100";
            NS<=ST4;
        when ST4 =>
        --prende il valore del numero di soglia e lo salva, quindi chiede l'elemento 0,0
            soglia<=i_data;
            last<="0000000000000101";
            o_address<="0000000000000101";
            rigaCorrente <= "00000000";
            colonnaCorrente <= "00000000";
            rigaPrecedente <= "00000000";
            colonnaPrecedente <= "00000000";
            NS<=ST5;
        when ST5 =>
        --prende il valore della cella chiesta e richiede il successivo
            if (last="0000000000000101") then
                        rigaCorrente<="00000000";
                        colonnaCorrente<="00000000";
            elsif (colonnaPrecedente=colonne-1)
                then
                    colonnaCorrente<="00000000"; 
                    rigaCorrente<=rigaPrecedente+1;
            else    
                colonnaCorrente<=colonnaPrecedente+1;
            end if;
            
            current<=last + "0000000000000001";
            NS<=ST6;
        when ST6=>
            colonnaPrecedente<=colonnaCorrente;
            rigaPrecedente<=rigaCorrente;
            last<=current;
            if (current>"0000000000000101"+righe*colonne)
               then NS<=ST8;
            else
               o_address<=last;
               o_en<='1';
               o_we<='0';
               NS<=ST7;  
            end if;        
        when ST7 =>
            
        -- Imposta i valori di riga e colonna minima e massima
            if (i_data>=soglia) then 
                    if (((colonnaMinima = "UUUUUUUU") OR (colonnaCorrente<colonnaMinima)) AND (colonnaCorrente<=colonne-1)) then 
                    colonnaMinima<=colonnaCorrente;
                    end if;
                    if (((colonnaMassima = "UUUUUUUU") OR (colonnaCorrente>colonnaMassima)) AND (colonnaCorrente<=colonne-1)) then
                    colonnaMassima<=colonnaCorrente;
                    end if;
                    if (((rigaMinima = "UUUUUUUU") OR (rigaCorrente<rigaMinima)) AND (rigaCorrente<=righe-1)) then
                    rigaMinima<=rigaCorrente;
                    end if;
                    if (((rigaMassima = "UUUUUUUU") OR (rigaCorrente>rigaMassima)) AND (rigaCorrente<=righe-1)) then
                    rigaMassima<=rigaCorrente;
                    end if;            
            end if;        
            o_en<='0';
            NS<=ST5;
        when ST8 =>
        -- Calcola l'area e ne scrive la parte più significtiva nel primo indirizzo in memoria
            if ((colonnaMinima = "UUUUUUUU") AND (rigaMinima = "UUUUUUUU") AND (colonnaMassima = "UUUUUUUU") AND (rigaMassima = "UUUUUUUU")) then
                area<="0000000000000000";   
            else 
                if (colonnaMinima = "UUUUUUUU") then
                colonnaMinima<=colonnaMassima;
                end if;
                if (rigaMinima = "UUUUUUUU")  then
                rigaMinima<=rigaMassima;
                end if;
                area<=(rigaMassima-rigaMinima+1)*(colonnaMassima-colonnaMinima+1); 
            end if;
            o_data<=area(15 downto 8);
            o_address<="0000000000000001";
            o_en<='1';
            o_we<='1';
            NS<=ST9;
        when ST9 =>
            NS<=ST10;
        when ST10 =>
        -- Scrive la parte meno significtiva dell'area nel secondo indirizzo in memoria
            o_data<=area(7 downto 0);            
            o_address<="0000000000000000";
            o_en<='1';
            o_we<='1';
            o_done<='1';
            NS<=ST11;
        when ST11 =>
            o_done<='0';
        when others =>
            NS<=ST7;
        end case;    
        
end process comb_proc;
end Behavioral;
