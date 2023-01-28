#!/bin/bash

# Trabalho realizado por: 
# André Oliveira		107637
# Duarte Cruz           107359

cd /proc

declare -a processID            # declaração de arrays 
declare -a infoProcess  
declare -a allRchar
declare -a allWchar

declare sT=${@: -1}             #segundos selecionados para leitura dos processos
declare numero_processos="null" #variável de armazenamento do número de processos a dar print
declare comm=".*"               #por default, se não forem colocados argumentos, serão analisados todos os processos
declare user="*"                #por default, se não forem colocados argumentos, serão analisados todos os processos de todos os utilizadores
declare min_pids="null"         #gama mínima de PIDS se o utilizador pretender
declare Max_pids="null"         #gama máxima de PIDS se o utilizador pretender
declare reverse=0               #variável de ativação da ordenação reversa
declare inicial_Date=0                                                 
declare final_Date=$(date +"%s")
declare sort_type=6             #sem nehuma indicação, a tabela será ordenada inersamente à sua taxa de leitura

numInt(){                               #função para validar se um número é inteiro positivo 
    if [[ "$sT" =~ ^[0-9]+$ && $sT != 0 ]]; then
        return 0
    else
        return 1
    fi
}

validarNumProcessos(){
    if [[ $numero_processos -gt ${#processID[@]} ]]; then         #erro se número de processos superior à quantidade de PID
        echo "ERRO: Número de processos pedidos superior ao número de processos existentes"
        exit 1
    elif [[ "$numero_processos" == "null" ]]; then                #por default usa o número total de PID's disponíveis
        numero_processos=${#processID[@]}
    fi
}

inputs(){
    while getopts ":s:e:c:u:p:m:M:wr" opt; do
        case $opt in
            s)
                date=$OPTARG
                if date -d "$date" >/dev/null 2>&1; then                                       
                    inicial_Date=$(date --date="$date" +"%s")            #data apenas é guardada se for válida
                else 
                    echo "ERRO: Data de início inválida"                 #erro
                    exit 1
                fi;;

            e)     
                date=$OPTARG  

                if date -d "$date" >/dev/null 2>&1; then
                    final_Date=$(date --date="$date" +"%s")              #data apenas é guardada se for válida
                else 
                    echo "ERRO: Data de fim inválida"                    #erro
                    exit 1
                fi

                if [[ $final_Date -le $inicial_Date ]]; then             #caso a data final for menor que a data inicial, dá erro
                    echo "ERRO: A data final é menor que a data inicial"
                    exit 1 
                fi;;

            c)
                comm=$OPTARG;;

            u)                                                                                          
                user=$OPTARG;;  

            p)
                if numInt $OPTARG; then
                    numero_processos=$OPTARG                             #número apenas é guardado se for válido
                else
                    echo "ERRO: Número de processos inválido"            #erro
                    exit 1
                fi;;

            m)
                if numInt $OPTARG; then
                    min_pids=$OPTARG                                               #número apenas é guardado se for válido
                else
                    echo "ERRO: Número mínimo de gama de pids inválido"            #erro
                    exit 1
                fi;; 
            
            M)
                if numInt $OPTARG; then
                    if [[ $min_pids -lt $OPTARG ]]; then
                        Max_pids=$OPTARG                                #número apenas é guardado se for válido
                    else
                        echo "ERRO: Número máximo da gama de pids deve ser maior que a gama de pids mínima"            #erro
                        exit 1
                    fi
                else 
                    echo "ERRO: Número máximo de gama de pids inválido"            #erro
                    exit 1
                fi;;
            
            w)
                sort_type=5;;

            r)
                reverse=1;;
            
            *)
                echo "ERRO: Opção inválida"             #erro caso tenha sido inserida uma opção inválida
                exit 1;;
        esac
    done
    shift $((OPTIND - 1))
}

printInfo(){
    printf "%-30s %-20s %15s %15s %15s %15s %15s %8s %-1s %-1s\n" ${infoProcess[@]}
}

print(){
    if [[ $numero_processos != 0 ]]; then
        printf "%-30s %-20s %15s %15s %15s %15s %15s %17s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
        if [[ $reverse -eq 0 ]]; then           #método para ordenação da tabela, com ou sem inversão
            case $sort_type in
                5) printInfo $min_pids $Max_pids | sort -k5rn | head -n $numero_processos;;
                6) printInfo $min_pids $Max_pids | sort -k6rn | head -n $numero_processos;;
            esac
        else
            case $sort_type in
                5) printInfo $min_pids $Max_pids | sort -k5n | head -n $numero_processos;;
                6) printInfo $min_pids $Max_pids | sort -k6n | head -n $numero_processos;;
            esac
        fi
    else
        echo "AVISO: Processos não encontrados"        #Aviso caso não haja PID's para imprimir
        exit 1
    fi
}

main(){
	inputs "$@"

    index=0
    if numInt $sT; then
        printf "A analisar processos...\n"
        echo ""
        for k in $(ls -a | grep -Eo '[0-9]{1,5}'); do                          #agrupar os números e percorrê-los um a um
            if [[ -f "$k/status" && -f "$k/io" && -f "$k/comm" ]]; then        #validar se o ficheiro que queremos existe
                if [[ -r "$k/status" && -r "$k/io" && -r "$k/comm" ]]; then    #confirmar a permissão de leitura dos ficheiros
                    if $(cat $k/io | grep -q 'rchar\|wchar') ; then            #verificar se existe a informação rchar e wchar
                        pComm=$(cat $k/comm)                                #pComm = nome do processo em questão
                        pUser=$(ps -o user= -p $k)                          #pUser = utilizador do processo
                        LANG=en_us_8859_1
                        startDate=$(ps -o lstart= -p $k)                       #data de começo do processo em questão
                        startDate=$(date +"%b %d %H:%M" -d "$startDate")       #formatação da data
                        data_seg=$(date --date="$startDate" +"%s")       

                        if [[ ($pComm =~ $comm) && ($pUser == $user) && ($data_seg -gt $inicial_Date) && ($data_seg -lt $final_Date) ]]; then
                            if [[ $min_pids != "null" || $Max_pids != "null" ]]; then
                                if [[ "$min_pids" != "null" && "$Max_pids" == "null" ]]; then
                                    if [[ $k -ge $min_pids ]]; then
                                        if ! [[ "${processID[@]}" =~ "$k" ]]; then    #verificar se o PID já existe em processID para evitar processos repetidos
                                            processID[index]=$k                             #forma de guardar os PID
                                            ((index++))
                                        fi
                                    fi
                                fi
                                if [[ "$min_pids" == "null" && "$Max_pids" != "null" ]]; then
                                    if [[ $k -le $Max_pids ]]; then                     
                                        if ! [[ "${processID[@]}" =~ "$k" ]]; then    #verificar se o PID já existe em processID para evitar processos repetidos
                                            processID[index]=$k                             #forma de guardar os PID
                                            ((index++))
                                        fi
                                    fi
                                fi
                                if [[ "$min_pids" != "null" && "$Max_pids" != "null" ]]; then
                                    if [[ $k -ge $min_pids && $k -le $Max_pids ]]; then 
                                        if ! [[ "${processID[@]}" =~ "$k" ]]; then    #verificar se o PID já existe em processID para evitar processos repetidos
                                            processID[index]=$k                             #forma de guardar os PID
                                            ((index++))
                                        fi
                                    fi
                                fi
                            else
                                if ! [[ "${processID[@]}" =~ "$k" ]]; then          #verificar se o PID já existe em processID para evitar processos repetidos
                                    processID[index]=$k                             #forma de guardar os PID
                                    ((index++))
                                fi 
                            fi
                        fi
                    fi
                fi
            fi
        done
    else
        echo "ERRO: SleepTime não é um número inteiro positivo ou não existe"            #erro
        exit 1
    fi

    validarNumProcessos $numero_processos        

    index=0
    for PID in ${processID[@]}; do                    #guardar rchars e wchars para cada processo
        rvalue=$(cat $PID/io | grep 'rchar')
        wvalue=$(cat $PID/io | grep 'wchar')
        rchar=${rvalue//[!0-9]/} 
        wchar=${wvalue//[!0-9]/}
                                
        allRchar[$index]=$rchar                       #guarda rchars
        allWchar[$index]=$wchar                       #guarda wchars
                                
        ((index++))
    done

    sleep $sT

    index=0
    for PID in ${processID[@]}; do
        rchar=${allRchar[$index]}                                                      #antes do sleep time
        wchar=${allWchar[$index]}

        ((index++))

        rvalue=$(cat $PID/io | grep 'rchar')
        wvalue=$(cat $PID/io | grep 'wchar')
        rchar2=${rvalue//[!0-9]/}                                                      #depois do sleep time
        wchar2=${wvalue//[!0-9]/}

        dif=$(($rchar2-$rchar))                                                       #diferença entre os valores após e antes do sleep time
        rater=$( echo "scale=2; $dif/$sT"| bc -l)                                     #rater = .01
        rater=${rater/#./0.}                                                     #rater = 0.01, acrescenta o zero

        sub=$(($wchar2-$wchar))                                                   #diferença entre os valores após e antes do sleep time
        ratew=$( echo "scale=2; $sub/$sT"| bc -l)                                 #ratew = .01               
        ratew=${ratew/#./0.}                                                       #ratew = 0.01, acrescenta o zero

        comm=$(cat $PID/comm | tr " " "_" )    

        LANG=en_us_8859_1 
        startDate=$(ps -o lstart= -p $PID)                                         #data de inicio do processo em questão
        date=$(date +"%b %d %H:%M" -d "$startDate")                                 #formatção da data

        user=$(ps -o user= -p $PID)

        infoProcess+=($comm $user $PID $dif $sub $rater $ratew $date)           #guarda as informações recolhidas de um processo em infoProcess
    done  

    print $numero_processos $sort_type $reverse $min_pids $Max_pids
}

main "$@"