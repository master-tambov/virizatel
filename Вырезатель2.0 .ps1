Add-Type -AssemblyName System.Windows.Forms

# Переменные
$fileSelected = ""
$linesToCopy = 0
$previousContent = @()   
$lineCount = 0           
$tempDir = "$env:TEMP\StringCutterTemp"  
New-Item -ItemType Directory -Force -Path $tempDir > $null

# Доступные кодировки поддерживаемые PowerShell
$encodings = @{
    "UTF-8"       = "utf8";
    "ASCII"       = "ascii";
    "Unicode"     = "unicode";          # UTF-16LE
    "BigEndianUnicode"= "bigendianunicode"; # UTF-16BE
    "Default"     = "default";          # Текущая кодировка системы
}

# Главная форма
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Вырезатель строк"
$Form.Width = 450
$Form.Height = 500
$Form.StartPosition = "CenterScreen"

# Русификация интерфейса
$LabelSelectFile = New-Object System.Windows.Forms.Label
$LabelSelectFile.Location = New-Object System.Drawing.Point(10,10)
$LabelSelectFile.Size = New-Object System.Drawing.Size(280,20)
$LabelSelectFile.Text = "Выберите файл:"

$ButtonSelectFile = New-Object System.Windows.Forms.Button
$ButtonSelectFile.Location = New-Object System.Drawing.Point(10,35)
$ButtonSelectFile.Size = New-Object System.Drawing.Size(120,30)
$ButtonSelectFile.Text = "Выбрать файл"

$LabelResult = New-Object System.Windows.Forms.Label
$LabelResult.Location = New-Object System.Drawing.Point(10,70)
$LabelResult.Size = New-Object System.Drawing.Size(430,30)
$LabelResult.ForeColor = "Green"

$LabelLineCount = New-Object System.Windows.Forms.Label
$LabelLineCount.Location = New-Object System.Drawing.Point(10,100)
$LabelLineCount.Size = New-Object System.Drawing.Size(430,30)
$LabelLineCount.ForeColor = "Black"

$LabelCount = New-Object System.Windows.Forms.Label
$LabelCount.Location = New-Object System.Drawing.Point(10,130)
$LabelCount.Size = New-Object System.Drawing.Size(150,20)
$LabelCount.Text = "Количество строк:"

$TextBoxCount = New-Object System.Windows.Forms.TextBox
$TextBoxCount.Location = New-Object System.Drawing.Point(160,130)
$TextBoxCount.Size = New-Object System.Drawing.Size(100,20)

$LabelEncoding = New-Object System.Windows.Forms.Label
$LabelEncoding.Location = New-Object System.Drawing.Point(10,160)
$LabelEncoding.Size = New-Object System.Drawing.Size(150,20)
$LabelEncoding.Text = "Кодировка файла:"

$ComboBoxEncodings = New-Object System.Windows.Forms.ComboBox
$ComboBoxEncodings.DropDownStyle = "DropDownList"
$ComboBoxEncodings.Items.AddRange(($encodings.Keys))
$ComboBoxEncodings.SelectedIndex = 0
$ComboBoxEncodings.Location = New-Object System.Drawing.Point(160,160)
$ComboBoxEncodings.Size = New-Object System.Drawing.Size(100,20)

$ButtonProcess = New-Object System.Windows.Forms.Button
$ButtonProcess.Location = New-Object System.Drawing.Point(10,190)
$ButtonProcess.Size = New-Object System.Drawing.Size(120,30)
$ButtonProcess.Text = "Обработать"

$ButtonUndo = New-Object System.Windows.Forms.Button
$ButtonUndo.Location = New-Object System.Drawing.Point(140,190)
$ButtonUndo.Size = New-Object System.Drawing.Size(120,30)
$ButtonUndo.Text = "Отменить операцию"

$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Location = New-Object System.Drawing.Point(10,230)
$StatusLabel.Size = New-Object System.Drawing.Size(430,30)
$StatusLabel.ForeColor = "Blue"

$ButtonClose = New-Object System.Windows.Forms.Button
$ButtonClose.Location = New-Object System.Drawing.Point(10,300)
$ButtonClose.Size = New-Object System.Drawing.Size(120,30)
$ButtonClose.Text = "Закрыть"

# Выбор файла
$ButtonSelectFile.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Выберите текстовый файл"
    $OpenFileDialog.Filter = "Текстовые файлы (*.txt)|*.txt|Все файлы (*.*)|*.*"
    if ($OpenFileDialog.ShowDialog() -eq "OK") {
        $global:fileSelected = $OpenFileDialog.FileName
        if (-not (Test-Path $fileSelected)) {
            $LabelResult.Text = "Файл не найден: $fileSelected"
            $LabelResult.ForeColor = "Red"
        } else {
            $LabelResult.Text = "Выбран файл: $fileSelected"
            $LabelResult.ForeColor = "Green"
            UpdateLineCount
        }
    }
})

# Обновляем счётчик строк
function UpdateLineCount {
    if ([string]::IsNullOrEmpty($fileSelected)) { return }
    # Чтение файла с выбранной кодировкой
    $encoding = $encodings[$ComboBoxEncodings.SelectedItem]
    $global:lineCount = @(Get-Content $fileSelected -Encoding $encoding).Count
    $LabelLineCount.Text = "Количество строк в файле: $lineCount"
}

# Обработка файла
$ButtonProcess.Add_Click({
    if ([string]::IsNullOrEmpty($fileSelected)) {
        $StatusLabel.Text = "Сначала выберите файл!"
        $StatusLabel.ForeColor = "Red"
        return
    }

    try {
        $global:linesToCopy = [int]$TextBoxCount.Text
        if ($linesToCopy -le 0) {
            throw "Введите положительное число строк."
        }
    
        # Получаем выбранную кодировку
        $selectedEncoding = $encodings[$ComboBoxEncodings.SelectedItem]
    
        # Создаем резервную копию файла
        Copy-Item $fileSelected "$tempDir\$(Split-Path -Leaf $fileSelected)_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
    
        # Читаем содержимое файла с указанной кодировкой
        $content = Get-Content $fileSelected -Encoding $selectedEncoding
        
        # Проверка количества строк
        if ($content.Count -lt $linesToCopy) {
            $StatusLabel.Text = "Недостаточно строк в файле для выбранного количества."
            $StatusLabel.ForeColor = "Red"
            return
        }
    
        # Копируем первые строки в буфер обмена
        $firstLines = $content | Select-Object -First $linesToCopy
        $firstLines | Set-Clipboard
    
        # Оставшиеся строки записываем обратно
        $remainingLines = $content | Select-Object -Skip $linesToCopy
        $remainingLines | Set-Content -Encoding $selectedEncoding $fileSelected
    
        # Сообщаем о результате
        $currentTime = Get-Date -Format "HH:mm:ss"
        $StatusLabel.Text = "Строки успешно скопированы в буфер обмена! Время изменения: $currentTime"
        $StatusLabel.ForeColor = "Green"
    
        # Обновляем счётчик строк
        UpdateLineCount
    } catch {
        $StatusLabel.Text = "Ошибка: $_"
        $StatusLabel.ForeColor = "Red"
    }
})

# Откат предыдущей операции
$ButtonUndo.Add_Click({
    if ((Get-ChildItem $tempDir | Where-Object {$_.Extension -like '*.bak'}).Count -eq 0) {
        $StatusLabel.Text = "Нет предыдущих изменений для восстановления."
        $StatusLabel.ForeColor = "Red"
        return
    }
    
    try {
        # Выбираем самую свежую резервную копию
        $lastBackup = Get-ChildItem $tempDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        # Проверяем существование резервной копии
        if (!(Test-Path $lastBackup.FullName)) {
            $StatusLabel.Text = "Резервная копия не найдена."
            $StatusLabel.ForeColor = "Red"
            return
        }
    
        # Возвращаем файл из резервной копии
        Move-Item $lastBackup.FullName $fileSelected -Force
    
        # Удаляем резервную копию, если она осталась
        if(Test-Path $lastBackup.FullName){
            Remove-Item $lastBackup.FullName
        }
    
        $StatusLabel.Text = "Операция успешно отменена!"
        $StatusLabel.ForeColor = "Green"
        
        # Обновляем количество строк
        UpdateLineCount
    } catch {
        $StatusLabel.Text = "Ошибка: $_"
        $StatusLabel.ForeColor = "Red"
    }
})

# Завершаем работу программы
$ButtonClose.Add_Click({$Form.Close()})

# Добавляем элементы управления на форму
$Form.Controls.AddRange(@(
    $LabelSelectFile,
    $ButtonSelectFile,
    $LabelResult,
    $LabelLineCount,
    $LabelCount,
    $TextBoxCount,
    $LabelEncoding,
    $ComboBoxEncodings,
    $ButtonProcess,
    $ButtonUndo,
    $StatusLabel,
    $ButtonClose
))

# Открытие окна
$Form.ShowDialog()