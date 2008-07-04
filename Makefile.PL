use inc::Module::Install;

name 'Sub-Auto';
license 'perl';
all_from 'lib/Sub/Auto.pm';

requires 'Class::AutoloadCAN';
requires 'Devel::Declare';


WriteAll;
