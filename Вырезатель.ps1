Add-Type -AssemblyName System.Windows.Forms

# Основные переменные
$fileSelected = ""
$linesToCopy = 0

# Основная форма
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Вырезатель строк"
$Form.Width = 400
$Form.Height = 300
$Form.StartPosition = "CenterScreen"

# Поле для выбора файла
$LabelSelectFile = New-Object System.Windows.Forms.Label
$LabelSelectFile.Location = New-Object System.Drawing.Point(10,10)
$LabelSelectFile.Size = New-Object System.Drawing.Size(280,20)
$LabelSelectFile.Text = "Выберите файл:"

$ButtonSelectFile = New-Object System.Windows.Forms.Button
$ButtonSelectFile.Location = New-Object System.Drawing.Point(10,30)
$ButtonSelectFile.Size = New-Object System.Drawing.Size(120,30)
$ButtonSelectFile.Text = "Выбрать файл"

# Метка результата выбора файла
$LabelResult = New-Object System.Windows.Forms.Label
$LabelResult.Location = New-Object System.Drawing.Point(10,60)
$LabelResult.Size = New-Object System.Drawing.Size(380,30)
$LabelResult.ForeColor = "Green"

# Количество строк
$LabelCount = New-Object System.Windows.Forms.Label
$LabelCount.Location = New-Object System.Drawing.Point(10,90)
$LabelCount.Size = New-Object System.Drawing.Size(150,20)
$LabelCount.Text = "Количество строк:"

$TextBoxCount = New-Object System.Windows.Forms.TextBox
$TextBoxCount.Location = New-Object System.Drawing.Point(160,90)
$TextBoxCount.Size = New-Object System.Drawing.Size(100,20)

# Кнопка Продолжить
$ButtonProcess = New-Object System.Windows.Forms.Button
$ButtonProcess.Location = New-Object System.Drawing.Point(10,120)
$ButtonProcess.Size = New-Object System.Drawing.Size(120,30)
$ButtonProcess.Text = "Продолжить"

# Статус выполнения
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Location = New-Object System.Drawing.Point(10,160)
$StatusLabel.Size = New-Object System.Drawing.Size(380,30)
$StatusLabel.ForeColor = "Blue"

# Закрывающая кнопка
$ButtonClose = New-Object System.Windows.Forms.Button
$ButtonClose.Location = New-Object System.Drawing.Point(10,220)
$ButtonClose.Size = New-Object System.Drawing.Size(120,30)
$ButtonClose.Text = "Закрыть"

# Функционал кнопок
$ButtonSelectFile.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Выберите текстовый файл"
    $OpenFileDialog.Filter = "Text Files (*.txt)|*.txt|Все файлы (*.*)|*.*"
    if ($OpenFileDialog.ShowDialog() -eq "OK") {
        $global:fileSelected = $OpenFileDialog.FileName
        $LabelResult.Text = "Выбрали файл: $fileSelected"
    }
})

$ButtonProcess.Add_Click({
    if ([string]::IsNullOrEmpty($fileSelected)) {
        $StatusLabel.Text = "Сначала выберите файл!"
        return
    }

    try {
        $global:linesToCopy = [int]$TextBoxCount.Text
        if ($linesToCopy -le 0) {
            throw "Введенное значение должно быть больше нуля."
        }
    
        # Чтение содержимого файла
        $content = Get-Content $fileSelected
        
        # Проверяем, достаточно ли строк в файле
        if ($content.Count -lt $linesToCopy) {
            $StatusLabel.Text = "Невозможно обработать: количество строк в файле меньше указанного значения."
            return
        }
    
        # Копируем первые строки в буфер обмена
        $firstLines = $content | Select-Object -First $linesToCopy
        $firstLines | Set-Clipboard
    
        # Остальное содержимое переписывается назад в файл
        $remainingLines = $content | Select-Object -Skip $linesToCopy
        Set-Content $fileSelected -Value $remainingLines
    
        $StatusLabel.Text = "Строки скопированы в буфер обмена!"
    } catch {
        $StatusLabel.Text = "Ошибка: $_"
    }
})

$ButtonClose.Add_Click({$Form.Close()})

# Добавление элементов на форму
$Form.Controls.AddRange(
    @($LabelSelectFile,
      $ButtonSelectFile,
      $LabelResult,
      $LabelCount,
      $TextBoxCount,
      $ButtonProcess,
      $StatusLabel,
      $ButtonClose)
)

# Отображение формы
$Form.ShowDialog()