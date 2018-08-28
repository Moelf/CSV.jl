using Dates, WeakRefStrings, CategoricalArrays

@testset "CSV.write" begin

    io = IOBuffer()
    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io)
    @test String(take!(io)) == "col1,col2,col3\n1,4,7\n2,5,8\n3,6,9\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; delim='\t')
    @test String(take!(io)) == "col1\tcol2\tcol3\n1\t4\t7\n2\t5\t8\n3\t6\t9\n"

    (col1=[1,2,3], col2=["hey", "the::re", "::sailor"], col3=[7,8,9]) |> CSV.write(io; delim="::")
    @test String(take!(io)) == "col1::col2::col3\n1::hey::7\n2::\"the::re\"::8\n3::\"::sailor\"::9\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; header=[:Col1, :Col2, :Col3])
    @test String(take!(io)) == "Col1,Col2,Col3\n1,4,7\n2,5,8\n3,6,9\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; header=["Col1", "Col2", "Col3"])
    @test String(take!(io)) == "Col1,Col2,Col3\n1,4,7\n2,5,8\n3,6,9\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; writeheader=false)
    @test String(take!(io)) == "1,4,7\n2,5,8\n3,6,9\n"

    # various types
    data = codeunits("hey there sailor")
    weakrefs = WeakRefStringArray(data, [WeakRefString(pointer(data), 3), WeakRefString(pointer(data), 3), WeakRefString(pointer(data), 3)])
    cats = CategoricalVector{String, UInt32}(["b", "a", "b"])

    (col1=[true, false, true],
     col2=[4.1,5.2,4e10],
     col3=[NaN, Inf, -Inf],
     col4=[Date(2017, 1, 1), Date(2018, 1, 1), Date(2019, 1, 1)],
     col5=[DateTime(2017, 1, 1, 4, 5, 6, 7), DateTime(2018, 1, 1, 4, 5, 6, 7), DateTime(2019, 1, 1, 4, 5, 6, 7)],
     col6=["hey", "there", "sailor"],
     col7=[WeakRefString(pointer(data), 3), WeakRefString(pointer(data), 3), WeakRefString(pointer(data), 3)],
     col8=weakrefs,
     col9=cats,
    ) |> CSV.write(io)
    @test String(take!(io)) == "col1,col2,col3,col4,col5,col6,col7,col8,col9\ntrue,4.1,NaN,2017-01-01,2017-01-01T04:05:06.007,hey,hey,hey,b\nfalse,5.2,Inf,2018-01-01,2018-01-01T04:05:06.007,there,hey,hey,a\ntrue,4.0e10,-Inf,2019-01-01,2019-01-01T04:05:06.007,sailor,hey,hey,b\n"

    (col4=[Date(2017, 1, 1), Date(2018, 1, 1), Date(2019, 1, 1)],
     col5=[DateTime(2017, 1, 1, 4, 5, 6, 7), DateTime(2018, 1, 1, 4, 5, 6, 7), DateTime(2019, 1, 1, 4, 5, 6, 7)],
    ) |> CSV.write(io; dateformat="mm/dd/yyyy")
    @test String(take!(io)) == "col4,col5\n01/01/2017,01/01/2017\n01/01/2018,01/01/2018\n01/01/2019,01/01/2019\n"

    (col1=[1,missing,3], col2=[missing, missing, missing], col3=[7,8,9]) |> CSV.write(io)
    @test String(take!(io)) == "col1,col2,col3\n1,,7\n,,8\n3,,9\n"

    (col1=[1,missing,3], col2=[missing, missing, missing], col3=[7,8,9]) |> CSV.write(io; missingstring="NA")
    @test String(take!(io)) == "col1,col2,col3\n1,NA,7\nNA,NA,8\n3,NA,9\n"

    (col1=["hey, there, sailor", "this, also, has, commas", "this\n has\n newlines\n", "no quoting", "just a random \" quote character", ],) |> CSV.write(io)
    @test String(take!(io)) == "col1\n\"hey, there, sailor\"\n\"this, also, has, commas\"\n\"this\n has\n newlines\n\"\nno quoting\njust a random \" quote character\n"

    (col1=["\"hey there sailor\""],) |> CSV.write(io)
    @test String(take!(io)) == "col1\n\"\\\"hey there sailor\\\"\"\n"

    (col1=["{\"key\": \"value\"}", "{\"key\": null}"],) |> CSV.write(io; openquotechar='{', closequotechar='}')
    @test String(take!(io)) == "col1\n{\\{\"key\": \"value\"\\}}\n{\\{\"key\": null\\}}\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io)
    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; append=false) # this is the default
    @test String(take!(io)) == "col1,col2,col3\n1,4,7\n2,5,8\n3,6,9\n"

    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io)
    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io; append=true)
    @test String(take!(io)) == "col1,col2,col3\n1,4,7\n2,5,8\n3,6,9\n1,4,7\n2,5,8\n3,6,9\n"

    file = "test.csv"
    (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(file)
    @test String(read(file)) == "col1,col2,col3\n1,4,7\n2,5,8\n3,6,9\n"
    rm(file)

    open(file, "w") do io
        (col1=[1,2,3], col2=[4,5,6], col3=[7,8,9]) |> CSV.write(io)
    end
    @test String(read(file)) == "col1,col2,col3\n1,4,7\n2,5,8\n3,6,9\n"
    rm(file)
    
end