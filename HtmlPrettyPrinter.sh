#!/bin/bash
#in cazul in care de la tastatura se da un nr invalid de argumente verificam pana cand se introduce numarul corect si daca path ul oferit este unul corect il salvam altfel sa mai dea argumente in continuare
if [ "$#" -ne 1 ]; then
    while true; do
        echo -n "Please enter only one path for the required argument:"
        read html_file 
        if [ ! -f "$html_file" ]; then 
            echo -n "Error: path to your $hmtl_file does not exist.Try again.\n"
        else if [ ! -s "$html_file" ]; then 
            echo -n "Error: $html_file is empty.Try again.\n"
            else
                break 
            fi
        fi 
    done
else 
    html_file="$1"
fi

#pun cu sed pe fiecare linie \n la inceput de < si \n la final de >
while IFS= read -r line; do
    echo "$line" | sed 's/</\n</g'| sed 's/>/>\n/g'| grep "\S" >> new_tags
done < "$html_file"
#sterg indentarile de la inceput de linie pentru a fi toate la acelasi nivels
sed -i 's/^[ \t]*//' new_tags

first_line=$(head -n 1 new_tags)
if [ "$first_line" != "<!DOCTYPE html>" ];then
    echo "The file does not correspond to a HTML file"
    exit 1
fi

self_closing_tags=("area" "base" "br" "col" "embed" "hr" "img" "input" "link" "meta" "param" "source" "track" "wbr" "!DOCTYPE")
#cu functia asta verific daca tag ul respectiv este self closing. daca nu este trebuie adaugat la dictionar 
is_self_closing(){
    local tag="$1"
    for sc_tag in "${self_closing_tags[@]}"; do
        if [[ "$tag" == "$sc_tag" ]]; then
            return 0
        fi
    done
return 1
}

declare -A tag_counts
while IFS= read -r line; do 
    tags=$(echo "$line" | grep -oP '(?<=<)[^<> ]+') #cu ajutorul lui grep reusesc sa caut text dupa un model anume, iar -o face ai sa afiseze doar portiunile de text care se potrivesc 
    for tag in $tags; do 
        if [[ "$tag" == /* ]]; then 
            tag="${tag:1}" #elimin primul caracter din tag care este /
            ((tag_counts["$tag"]--))
        else 
            if ! is_self_closing "$tag"; then
                ((tag_counts["$tag"]++))
            fi
        fi
    done
done < new_tags

for tag in "${!tag_counts[@]}";do #returneaza toate cheile din dictionar
    if [[ "${tag_counts[$tag]}" -ne 0 ]]; then 
        echo "Error: Number of opening tags is not equal to number of closing tabs!"
        exit 1
    fi
done

indent=0
dif_space=0
space=0

# fiecare linie va fi prefixata cu numarul de ordine in ierarhie
while IFS= read -r line; do 
    tag=$(echo "$line" | grep -oP '(?<=<)[^/<> ]+')
    if [ -n "$tag" ]; then 
        if ! is_self_closing "$tag"; then 
            line=$(printf "%s~%s" "$indent" "$line") #in acest moment am indentat linia cu indicele sau si caracterul ~ pentru a sti la final de cate space uri am nevoie pentru a adauga 
            indent=$((indent + 1))
        else
            line=$(printf "%s~%s" "$indent" "$line")
        fi
    else 
        tag=$(echo "$line" | grep -oP '(?<=</)[^/<> ]+')
        if [ -n "$tag" ]; then 
            indent=$((indent - 1))
            line=$(printf "%s~%s" "$indent" "$line")
        else #este secventa de text
            space=$(echo "$line" | sed 's/[^ ]*//g' | wc -c) #sed elimina orice caracter care nu este spatiu iar wc le numara 
            if (( space > 0 )); then
            space=$((space - 1))
            fi
            while (( space % 4 != 0 )); do
                line=${line:1}
                space=$((space - 1))
            done
            dif_space=$((indent * 4))
            dif_space=$((dif_space-space))
            dif_space=$((dif_space / 4))
            line=$(printf "%s~%s" "$dif_space" "$line")
        fi
    fi
    echo "$line" >> tmp_file
done < new_tags
cat tmp_file > new_tags
rm tmp_file

while IFS= read -r line; do
    indent=$(echo "$line" | grep -oP "^[0-9]+")
    indent=$((indent * 4))
    space_string=$(printf '%*s' "$indent")
    echo "$line" | sed  -E "s/^[0-9]+~/$space_string/g" >> tmp_file
done < new_tags

cat tmp_file > new_tags
rm tmp_file

cat new_tags > "pretty_printer"
rm new_tags

#deci ideea in momentul de fata este ca fiecare tag/text/wtvr sa fie pe linia sa proprie.
#pot sa fac asta dar exista nenumarate cazuri in care tag urile sunt imprastiate peste tot deci trebuie mai intai
#sa vad indentarea la stanga la dreapta si sa vad daca dupa fiecare \n mai exista indentare ca toate elementele
#sa fie la inceput de linie indiferent de pozitia lor in html

#problema cea mai mare a unui input invalid este cazul in care un tag care nu este self closing nu are pereche. pentru a identifica existenta unei
#astfel de erori trebuie sa formam un dictionar care sa memoreze perechile pentru fiecare tag 
#in cazul in care gasesc un tag care nu este self closing il adaug la dictionar si ii cresc frecventa 
#intr un final daca frecventa tag-ului este una impara inseamna ca nu are pereche si ca input ul este unul invalid

#pentru secventa '(?<=<)[^<> ]+' specifica limbajului Perl, in teorie se ia numai textul din tag deoarece (?<=<) inseamna lookbehind adica 
#sa caut orice apare dupa caracterul <, iar [^<>] inseamna orice caracter care nu este < sau >, iar + semnifica ca se pot potrivi mai multe secv de genul

#ca idee principala pentru identare este gasesti tagul de inceput si retii indexul, iar in momentul in care ai gasit un tag de final il decrementezi
#in cazul in care tagul este unul self closing s