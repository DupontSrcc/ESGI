#Création VM
#Tardif Tom
#Date 12/06/2018
#Crée X  VM

#Fonction

Function Wmail ()

{

#serveur SMTP de GMAIL
$emailSmtpServer = ‘smtp.gmail.com’
# port utilisé, plusieurs possible, voici ici –> https://support.google.com/a/answer/176600?hl=fr
$emailSmtpServerPort = " 587 "
#votre adresse mail
$emailSmtpUser = "amara.199477@gmail.com"
# votre mot de passe
$emailSmtpPass = " sabrina1994. "




# on declare l’objet email
$emailMessage = New-Object System.Net.Mail.MailMessage
#expéditeur
$emailMessage.From = " Script-Email amara.199477@gmail.com "
#adresse du destinataire
$emailMessage.To.Add( $item.email )
#sujet du mail
$emailMessage.Subject = " Rapport de Création VM de " + $item.name
#mail version HMTL
$emailMessage.IsBodyHtml = $true
#contenu du mail
$emailMessage.Body = " Bonjour, la Machine Virutel " + $item.name + $infoVM

#renseignement des options de l’objet email
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );

#envoi le mail
$SMTPClient.Send( $emailMessage )

}




#VARIABLE

#import du module powercli
Add-PSSnapin VMware.VimAutomation.Core


#connection à l'ESXI
connect-viserver 192.168.100.50 -user "root" -password "Esgi1234" 



#Import du document .Csv avec le delimeter ":"
$csv = Import-Csv "C:\Users\cleme\Desktop\Master_1er_Année\Automatisation\vm-bis1.csv" -Delimiter ":"




#MAIN sSCRIPT

#lis chacune des colonnes (première ligne du document .csv) 

#$item contient l'ensemble des colonne et associé la variable

#$item.nomdelacolonne


ForEach ($item in $csv)

{

$name = $item.name

$nbcpu = $item.CPU

$Mem = $item.Mem

$format = $item.diskformat

$email = $item.email

# on declare l’objet email
$emailMessage = New-Object System.Net.Mail.MailMessage


Write-host $item #affiche la variable 
Write-Host "Souhaitez-vous crée la VM avec les informations suivantes ? "
Write-Host "-----" 
Write-Host "OUI" -ForegroundColor Green -NoNewline
Write-Host " ou " -NoNewline #Permet de rester sur la ligne
Write-Host "NON " -ForegroundColor Red #change la couleurs du texte
Write-Host "-----" 

Write-Host "Nom de la VM : " -NoNewLine  
write-host  $item.name -foregroundcolor cyan
 

Write-Host "Nombre de Cpu : " -NoNewLine
Write-Host  $item.CPU -foregroundcolor cyan
 
Write-Host "Nombre de Mémoire : " -NoNewLine 
Write-Host $item.Mem -foregroundcolor cyan

Write-Host "Fort du disque Dur : " -NoNewLine
Write-Host $item.diskformat -foregroundcolor cyan
Write-Host "-----------"  


 $Readhost = Read-Host "Réponse  " #textebox pour l'utilisateur
    if ($ReadHost -eq "oui" )  #selon les réponse éxecute une action : exemple affiche un texte
     { 
       Write-Host "-----------"  
       Write-host "Oui" -ForegroundColor Green -NoNewLine
       Write-Host ", la VM va être crée " ; $rep=$true 
       new-vm -Name $item.name -MemoryMB $item.mem -NumCpu $item.CPU -DiskStorageFormat $item.diskformat #Creer une VM avec les parametres spécifiés
       $infoVM= Get-VM -Name $item.name | Select-Object Name, NumCPU, MemoryMB #Stock les informations de la VM créer dans une variable
       Wmail #Appel de la fonction d'envoie de mail 
       
     
     } 
    if ($ReadHost -eq "non" )
     {
       Write-Host "-----------"  
       Write-Host "Non," -ForegroundColor Red -NoNewLine
       Write-Host " la vm ne sera pas crée" ; $rep=$false
       wmail
      
       
     }
    elseif ($ReadHost -eq "" )
     {
       Write-Host "-----------"  
       Write-host "Mauvaises réponse, annulation de la création des VM" -ForegroundColor Red ; $rep=$false}
}



Disconnect-VIServer -Server 10.33.1.155 -confirm:$false #Force la deconnexion du Serveur sans prompt une fois le script terminé 


#afficher les infos en couleur
#demander si c'est ok pour continuer ? 


#faire la boucle foreach propre (début et fin finir avant le if)
#importer le module powercli et faire la connexion au début
#fermer la connexion a la fin du code


