class DocumentsController < ApplicationController
  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      # Parse the Excel file and insert the data into the User model
      parse_and_insert_data(@document.file)
      redirect_to "/", notice: "File uploaded and data inserted successfully!"
    else
      render :new
    end
  end

  private

  def document_params
    params.require(:document).permit(:file)
  end

  # Method to parse and insert data into ActiveRecord model
  def parse_and_insert_data(file)
    xlsx = RubyXL::Parser.parse_buffer(file.download)

    # Assuming the first worksheet contains the data
    worksheet = xlsx[0]

    # Start at row 1 (since row 0 is usually the header row)
    worksheet.each_with_index do |row, index|
      next if index == 0 || index == 1 || index == 2 || index == 3  # Skip the header row

      # Assuming columns are: Name, Email
      timestamp = row[0]&.value.to_s
      email = row[1]&.value.to_s
      first_name = row[2]&.value.to_s
      last_name = row[3]&.value.to_s
      student_number = row[4]&.value.to_s
      faculty = row[5]&.value.to_s
      major = row[6]&.value.to_s
      year = row[7]&.value.to_s
      graudation_year = row[8]&.value.to_s
      position = row[9]&.value.to_s
      resume = row[10]&.value.to_s
      additional_info = row[11]&.value.to_s
      origin = row[12]&.value.to_s
      preference = row[13]&.value.to_s
      location = row[14]&.value.to_s
      careers = row[15]&.value.to_s

      Application.create!(
        application_date: timestamp,
        email: email,
        first_name: first_name,
        last_name: last_name,
        student_number: student_number,
        faculty: faculty,
        major: major,
        year: year,
        grad_year: graudation_year,
        position: position,
        resume: resume,
        additional: additional_info,
        source: origin,
        group_preference: preference,
        countries: location,
        careers: careers,
      )
    end
  end
end
